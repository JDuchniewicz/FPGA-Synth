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
#include <asm/io.h>

#define DEV_NAME            "dma-snd"

#define MSGDMA_MAP_SIZE     0x30

#define MSGDMA_MAX_TX_LEN   (1 << 10) // 1 KB
#define DMA_BUF_SIZE        (1 << 20) // 1 MB // TODO: tweak?

#define TX_TIMEOUT          HZ // 1 second

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

    struct msgdma_reg* msgdma0_reg; // only DMA this driver supports as we do reads only
    int msgdma0_irq;
    void* dma_buf_rd;
    dma_addr_t dma_buf_rd_handle;

    wait_queue_head_t rd_complete_wq;
    int rd_in_progress;
};

// stick to dma-snd naming convention even though for now we support just dma (without snd ALSA part)
/* Function declarations */
static int dma_snd_open(struct inode* node, struct file* f);
static int dma_snd_release(struct inode* node, struct file* f);
static ssize_t dma_snd_read(struct file* f, char __user* ubuf, size_t len, loff_t* off);

static int dma_snd_probe(struct platform_device* pdev);
static int dma_snd_remove(struct platform_device* pdev);

static const struct file_operations dma_snd_fops = {
    .owner      = THIS_MODULE,
    .open       = dma_snd_open, //we will not need it if DMA is running constantly, fo now leave as is
    .release    = dma_snd_release,
    .read       = dma_snd_read,
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