#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/dma-mapping.h>
#include <linux/interrupt.h>
#include <linux/slab.h>
#include <linux/cdev.h>
#include <linux/platform_device.h>
#include <linux/of_address.h>
#include <linux/uaccess.h>
#include <linux/interrupt.h>
#include <linux/wait.h>
#include <linux/time.h>
#include <linux/jiffies.h>
#include <sound/core.h>
#include <sound/control.h>
#include <sound/pcm.h>
#include <sound/initval.h>
#include <asm/io.h>

#define DEV_NAME            "dma_snd" // later rethink this name (maybe dma_vosc or fpga_vosc)?

#define MSGDMA_MAP_SIZE     0x30

/* ALSA constraints for efficient communication
 *
 *  PCM interrupt interval -> ex: 10ms
 *  Period -> how many frames per one PCM interrupt
 *  Frame -> 1 sample from all channels, here: 1 channel * 1 sample in bytes = 1 * 4 = 4 B
 */
#define MSGDMA_MAX_TX_LEN   (1 << 12) // 4 KB // TODO: this is set to 2KB in hw?
#define DMA_BUF_SIZE        (1 << 20) // 1 MB // TODO: tweak to 4MB?

#define TX_TIMEOUT          HZ // 1 second
#define DMA_TX_FREQ         HZ / 960

// assuming IRQ every 10 ms i.e. 100 in a second
#define PERIOD_SAMPLES      960
#define PERIOD_SIZE_BYTES   4 * PERIOD_SAMPLES
#define MAX_PERIODS_IN_BUF  100
#define MIN_PERIODS_IN_BUF  MAX_PERIODS_IN_BUF

static int debug = 0;
#undef dbg
#define dbg(format, arg...) do { if (debug) pr_info(": " format "\n", ##arg); } while (0)

typedef u32 volatile reg_t;

#pragma pack(1)
struct msgdma_reg {
    /* CSR port registers */
    reg_t csr_status;
    reg_t csr_ctrl;
    reg_t csr_fill_lvl;
    reg_t csr_resp_fill_lvl;
    reg_t csr_seq_num;
    reg_t csr_comp_conf1;
    reg_t csr_comp_conf2;
    reg_t csr_comp_info;

    /* Descriptor port registers */
    reg_t desc_read_addr;
    reg_t desc_write_addr;
    reg_t desc_len;
    reg_t desc_ctrl;

    /* Response port registers */ // currently not used (can be removed?) // TODO:
    reg_t resp_bytes_transferred;
    reg_t resp_term_err;
};
#pragma pack()

/* MSGDMA Register bit fields */
enum STATUS {
    IRQ                 = (1 << 9),
    STOPPED_EARLY_TERM  = (1 << 8),
    STOPPED_ON_ERR      = (1 << 7),
    RESETTING           = (1 << 6),
    STOPPED             = (1 << 5),
    RESP_BUF_FULL       = (1 << 4),
    RESP_BUF_EMPTY      = (1 << 3),
    DESC_BUF_FULL       = (1 << 2),
    DESC_BUF_EMPTY      = (1 << 1),
    BUSY                = (1 << 0),
};

enum CONTROL {
    STOP_DESC           = (1 << 5),
    GLOBAL_IRQ_EN       = (1 << 4),
    STOP_ON_EARLY_TERM  = (1 << 3),
    STOP_ON_ERR         = (1 << 2),
    RESET_DISP          = (1 << 1),
    STOP_DISP           = (1 << 0),
};

enum DESC_CTRL {
    GO                  = (1 << 31),
    WAIT_WRITE_RESP     = (1 << 25),
    EARLY_DONE_EN       = (1 << 24),
    TX_ERR_IRQ_EN       = (1 << 23),
    EARLY_TERM_IRQ_EN   = (1 << 15),
    TX_COMPL_IRQ_EN     = (1 << 14),
    END_ON_EOP          = (1 << 12),
    PARK_WRITES         = (1 << 11),
    PARK_READS          = (1 << 10),
    GEN_EOP             = (1 << 9),
    GEN_SOP             = (1 << 8),
    TX_CHANNEL          = (1 << 7),
};

/* Driver private data */
struct msgdma_data {
    dev_t dev_id;
    struct cdev cdev;

    struct msgdma_reg* msgdma0_reg;
    int msgdma0_irq;
    void* dma_buf_rd;
    dma_addr_t dma_buf_rd_handle;

    wait_queue_head_t rd_complete_wq;
    int rd_in_progress;

    // to be removed?
    struct class *cl;



    // FOR NOW COPIED FROM snd_pcm_device!! // TODO: rename and clean
    struct snd_card* card;
    struct snd_pcm* pcm;
    const struct dma_snd_pcm_ops* timer_ops;
    /* just one substream so keep all data in this struct */
    struct mutex cable_lock;
    /* flags */
    unsigned int valid;
    unsigned int running;
    unsigned int period_update_pending :1;
    /* timer stuff */
    unsigned int period_size;
    unsigned long last_jiffies;
    struct timer_list timer;

    struct snd_pcm_substream* substream; // do not make use of the runtime pointer, instead set all data by myself
    unsigned int buf_pos; /* position in buffer in bytes */
};

/* SND MINIVOSC Data */
#define byte_pos(x) ((x) / HZ)
#define frac_pos(x) ((x) * HZ)

static struct snd_pcm_hardware dma_snd_pcm_hw = { // for now prefix everything with dma_snd
    .info = (SNDRV_PCM_INFO_MMAP |
    SNDRV_PCM_INFO_INTERLEAVED |
    SNDRV_PCM_INFO_BLOCK_TRANSFER |
    SNDRV_PCM_INFO_MMAP_VALID),
    .formats            = SNDRV_PCM_FMTBIT_S24_LE, // for now store as 32-bit values with last byte zeroed out
    .rates              = SNDRV_PCM_RATE_96000,
    .rate_min           = 96000,
    .rate_max           = 96000,
    .channels_min       = 1,
    .channels_max       = 1, // can be extended to 2?
    .buffer_bytes_max   = DMA_BUF_SIZE,
    .period_bytes_min   = PERIOD_SIZE_BYTES, 
    .period_bytes_max   = PERIOD_SIZE_BYTES, // TODO: consult buffer sizes
    .periods_min        = MIN_PERIODS_IN_BUF, // TODO: this triggers how often a PCM interrupt is triggered, to tweak!!!!!
    .periods_max        = MAX_PERIODS_IN_BUF, // This is max number of periods in the buffer -> DMA_BUF_SIZE / period size
};

// stick to dma-snd naming convention even though for now we support just dma (without snd ALSA part)
/* Function declarations */
static int dma_snd_open(struct inode* node, struct file* f);
static int dma_snd_release(struct inode* node, struct file* f);
//static ssize_t dma_snd_read(struct file* f, char __user* ubuf, size_t len, loff_t* off);

static int dma_snd_probe(struct platform_device* pdev);
static int dma_snd_remove(struct platform_device* pdev);

/* ALSA functions */
static int dma_snd_pcm_open(struct snd_pcm_substream* ss);
static int dma_snd_pcm_close(struct snd_pcm_substream* ss);
static int dma_snd_hw_params(struct snd_pcm_substream* ss, struct snd_pcm_hw_params* hw_params);
//static int dma_snd_hw_free(struct snd_pcm_substream* ss);
static int dma_snd_prepare(struct snd_pcm_substream* ss);
static int dma_snd_pcm_trigger(struct snd_pcm_substream* ss, int cmd);
static int dma_snd_pcm_dev_free(struct snd_device* device);
static int dma_snd_pcm_free(struct msgdma_data* chip);
static snd_pcm_uframes_t dma_snd_pcm_pointer(struct snd_pcm_substream* ss);

/* timer functions */
static void dma_snd_timer_start(struct msgdma_data* mydev);
static void dma_snd_timer_stop(struct msgdma_data* mydev);
//static void dma_snd_pos_update(struct msgdma_data* mydev);
static void dma_snd_timer_function(unsigned long data);
/*
static void dma_snd_xfer_buf(struct msgdma_data* mydev, unsigned int count);
static void dma_snd_fill_capture_buf(struct msgdma_data* mydev, unsigned int bytes);
*/

static struct snd_pcm_ops dma_snd_pcm_ops = {
    .open       = dma_snd_pcm_open,
    .close      = dma_snd_pcm_close,
    .ioctl      = snd_pcm_lib_ioctl,
    .hw_params  = dma_snd_hw_params,
    //.hw_free    = dma_snd_hw_free,
    .prepare    = dma_snd_prepare,
    .trigger    = dma_snd_pcm_trigger,
    .pointer    = dma_snd_pcm_pointer,
};

/* specifies what function is called at snd_card_free - used in snd_device_new */
static struct snd_device_ops snd_dev_ops = {
    .dev_free   = dma_snd_pcm_dev_free,
};

static const struct file_operations dma_snd_fops = {
    .owner      = THIS_MODULE,
    .open       = dma_snd_open, //we will not need it if DMA is running constantly, fo now leave as is
    .release    = dma_snd_release,
   // .read       = dma_snd_read,
};


static const struct of_device_id dma_snd_of_match [] = {
    {.compatible = "altr,msgdma-19.1" }, // check if can freely change the name  in DTS // TODO:
    {}
};

static struct platform_driver dma_snd_driver = {
    .probe      = dma_snd_probe,
    .remove     = dma_snd_remove,
    .driver     = {
        .name = DEV_NAME,
        .of_match_table = dma_snd_of_match,
    },
};
//TODO: once working tweak the naming conventions etc so that it is more meaningful