#include "dma_snd.h"

/* Utility functions */
static void setbit_reg32(volatile void __iomem* reg, u32 mask)
{
    u32 val = ioread32(reg);
    iowrite32(val | mask, reg);
}

/*
static void clearbit_reg32(volatile void __iomem* reg, u32 mask)
{
    u32 val = ioread32(reg);
    iowrite32((val & (~mask)), reg);
}
*/

static void dma_snd_reset(struct msgdma_reg* reg)
{
    setbit_reg32(&reg->csr_ctrl, RESET_DISP);
    while (ioread32(&reg->csr_status) & RESETTING);
}

static void dma_snd_push_descr(
    struct msgdma_reg* reg,
    dma_addr_t read_addr,
    dma_addr_t write_addr,
    u32 len,
    u32 ctrl)
{
    iowrite32(read_addr, &reg->desc_read_addr);
    iowrite32(write_addr, &reg->desc_write_addr);
    iowrite32(len, &reg->desc_len);
    iowrite32(ctrl | GO, &reg->desc_ctrl);
}

/* ALSA functions */
static int dma_snd_pcm_open(struct snd_pcm_substream* ss)
{
    struct msgdma_data* mydev = ss->private_data;
    dbg("%s", __func__);
    mutex_lock(&mydev->cable_lock);

    // set runtime DMA buffer information
    ss->runtime->dma_area = mydev->dma_buf_rd;
    ss->runtime->dma_bytes = DMA_BUF_SIZE;
    ss->runtime->dma_addr = mydev->dma_buf_rd_handle;

    ss->runtime->hw = dma_snd_pcm_hw;

    mydev->substream = ss;
    ss->runtime->private_data = mydev;

    // SETUP TIMER here
    setup_timer(&mydev->timer, dma_snd_timer_function, (unsigned long)mydev);
    mutex_unlock(&mydev->cable_lock);
    return 0;
}

static int dma_snd_pcm_close(struct snd_pcm_substream* ss)
{
    struct msgdma_data* mydev = ss->private_data;
    dbg("%s", __func__);

    // even though the mutex will be set to null already, lock it
    mutex_lock(&mydev->cable_lock);
    ss->private_data = NULL;
    mutex_unlock(&mydev->cable_lock);
    return 0;
}

static int dma_snd_hw_params(struct snd_pcm_substream* ss, struct snd_pcm_hw_params* hw_params)
{
    dbg("%s", __func__);
    // nothing to do here
    return 0;
}
/*
static int dma_snd_hw_free(struct snd_pcm_substream* ss)
{
    dbg("%s", __func__);
    return snd_pcm_lib_free_pages(ss);
}
*/

static int dma_snd_prepare(struct snd_pcm_substream* ss)
{
    struct msgdma_data* mydev = ss->private_data;
    dbg("%s", __func__);

    mydev->buf_pos = 0;
    /*
    dbg("    runtime->buffer_size: %lu; mydev->pcm_buffer_size: %u",runtime->buffer_size, mydev->pcm_buffer_size);
    dbg("   runtime->dma_area %x runtime->dma_addr %x runtime->dma_size %d ", runtime->dma_area, runtime->dma_addr, runtime->dma_bytes);
    dbg("   mydev->ss->dma_buffer.area %x mydev->ss->dma_buffer.addr %x", mydev->substream->dma_buffer.area, mydev->substream->dma_buffer.addr);
    if (ss->stream == SNDRV_PCM_STREAM_CAPTURE) // TODO: does this memory have to be prepared at all?
    {
        // clear capture buffer 
        // mark prepared buffer as 45 -> '_'
        memset(runtime->dma_area, 45, DMA_BUF_SIZE);
    }
    */
    
    //dbg("This substream max DMA buffer size %d max DMA size %d DMA address %x Other max size parameter %d ", ss->buffer_bytes_max, ss->dma_max, ss->dma_buffer.addr, ss->dma_buffer.bytes);
    mutex_lock(&mydev->cable_lock);
    mydev->valid |= 1 << ss->stream;
    mutex_unlock(&mydev->cable_lock);

    return 0;
}

static int dma_snd_pcm_trigger(struct snd_pcm_substream* ss, int cmd)
{
    int ret = 0;
    // do not get mydev from ss->runtime->private_data but from
    struct msgdma_data* mydev = ss->private_data;
    dbg("%s - trigger %d", __func__, cmd);

    switch (cmd)
    {
        case SNDRV_PCM_TRIGGER_START:
            // start the hw capture
            if (!mydev->running)
            {
                mydev->last_jiffies = jiffies;
                // SET OFF the timer
                dma_snd_timer_start(mydev);
            }
            mydev->running |= 1 << ss->stream; // add a bitmask for each stream that is running (in our case just one)
            break;
        case SNDRV_PCM_TRIGGER_STOP:
            // stop the hw capture
            mydev->running &= ~(1 << ss->stream);
            if (!mydev->running)
                // STOP the timer 
                dma_snd_timer_stop(mydev);
            break;
        default:
            ret = -EINVAL;
    }
    return ret;
}

// HIGH LEVEL OVERVIEW OF MY SOLUTION
/*
    ZERO COPY!!!
    Data is filled by FPGA DMA to a buffer with 96kHz frequency
    Interrupt is generated each time a data arrives in the buffer? CHECK IT

    On the driver side, once applicaton requests a transfer, the data is already in the ALSA buffer but the pointer needs to travel through it
    Each time the 'transfer' is happening (the stream captures buffers contents), a period has elapsed, hence advance the buffer idx by whole data period -> size of one sample 24_LE
    Signal alsa that a period has elapsed and reenable IRQ's
    No timer needed now!!!

*/

// These functions would do any special freeing on snd_card_free, however no need to do anything since no special allocations made
static int dma_snd_pcm_dev_free(struct snd_device* device)
{
    dbg("%s", __func__);
    return dma_snd_pcm_free(device->device_data);
}

static int dma_snd_pcm_free(struct msgdma_data* chip)
{
    dbg("%s", __func__);
    return 0;
}

static snd_pcm_uframes_t dma_snd_pcm_pointer(struct snd_pcm_substream* ss)
{
    struct msgdma_data* mydev = ss->private_data; // TODO: change mydev to something more meaningful
    snd_pcm_uframes_t pos;
    dbg("%s", __func__);
    pos = bytes_to_frames(ss->runtime, mydev->buf_pos * BUFFER_SAMPLES);
    //dma_snd_pos_update(mydev); // TODO: should I update anything? probably not, just return the byte received
    dbg("   dma_snd_pcm_pointer %ld", pos);
    return pos;
}


/* timer functions */
static void dma_snd_timer_start(struct msgdma_data* mydev)
{
    /*
    dbg("   %s: mydev->period_size_frac: %u; mydev->irq_pos: %u jiffies: %lu pcm_bps %u",mydev->period_size_frac, mydev->irq_pos, mydev->pcm_bps);
    tick = mydev->period_size_frac - mydev->irq_pos; // how far are we in the current period of the waveform
    tick = (tick + mydev->pcm_bps - 1) / mydev->pcm_bps; // + pcm_bps to prevent negative value overflow
    */
    // update every 1/96000 second
    mydev->timer.expires = jiffies + SAMPLE_TIMEOUT;
    add_timer(&mydev->timer);
}

static void dma_snd_timer_stop(struct msgdma_data* mydev)
{
    dbg("%s", __func__);
    del_timer(&mydev->timer);
}

// shower thoughts -> why not make use of REAL DMA capabilites and transfer in chunks of 1K filling the buffer in advance? TODO: check it :)
// looks like it is working but needs tweaking and buffer wrapping?
// does the buffer extend indefinitely? what are its constraints? it should wrap somewhere?
// better use chunks instead of single sample transfers
static void dma_snd_timer_function(unsigned long data)
{
    struct msgdma_data* mydev = (struct msgdma_data*)data;
    struct snd_pcm_runtime* runtime = mydev->substream->runtime;

    if (!mydev->running)
        return;

// FOR NOW VERY SIMPLE LATER TWEAK SIZES TO MAKE USE OF WHOLE AVAILABLE DMA BUFFEr    

    dma_snd_push_descr(
        mydev->msgdma0_reg,
        0,
        runtime->dma_addr,
        BUFFER_SAMPLES, // write one whole buffer of samples each 4 bytes long
        TX_COMPL_IRQ_EN);

    ++mydev->buf_pos;
    if (mydev->buf_pos >= MAX_BUFFERS)
        mydev->buf_pos = 0;
    // SET OFF the timer
    dma_snd_timer_start(mydev);
}

/* Character file functions */
static int dma_snd_open(struct inode* node, struct file* f) // This is not needed when it is a misc device
{
    // TODO: single openness 
    struct msgdma_data* data;
    data = container_of(node->i_cdev, struct msgdma_data, cdev); // it works because node is registered with the pointer to cdev that is contained in msgdma data
    f->private_data = data;
    return 0;
}

static int dma_snd_release(struct inode* node, struct file* f)
{
    return 0; // really nothing to do?
}

// THIS IS THE LAZY DMA WAY, I WANT THE EAGER ONE (ASYNC)
/*
static ssize_t dma_snd_read(struct file* f, char __user* ubuf, size_t len, loff_t* off) // TODO: try incorporating it to ALSA xfer function -> here ALSA polls on the available signal, triggers HW IRQ which continues transfer until count bytes is transferred. The DMA mapped capture buffer is filled this way -> we have 1 copy from DMA memory to DMA memory
{
    struct msgdma_data* data;
    dma_addr_t read_addr;
    size_t to_read;
    ssize_t read_ret;
    int ret;

    dbg("Starting a DMA read, len %d ", len);
    data = (struct msgdma_data*)f->private_data;
    read_ret = len > DMA_BUF_SIZE ? DMA_BUF_SIZE : len;
    to_read = read_ret;

    // Start transfer 
    read_addr = data->dma_buf_rd_handle;
    while (to_read > MSGDMA_MAX_TX_LEN)
    {
        dbg("Reading bytes to_read: %d read_addr: %x", to_read, read_addr);
        dma_snd_push_descr( // check parameter order ( I think read is mixed with write)
            data->msgdma0_reg,
            0,
            MSGDMA_MAX_TX_LEN,
            0);

        to_read -= MSGDMA_MAX_TX_LEN;
        read_addr += MSGDMA_MAX_TX_LEN;
    }
     //Last descriptor sends an IRQ 
    dma_snd_push_descr(
        data->msgdma0_reg,
        0,
        read_addr, // write to the "read"
        to_read,
        TX_COMPL_IRQ_EN);
    dbg("Done reading bytes read_addr: %x", read_addr);
    
     //Wait for the transfer to complete 
    ret = wait_event_interruptible_timeout(
        data->rd_complete_wq,
        !data->rd_in_progress,
        TX_TIMEOUT);
    
    if (ret < 0)
        return -ERESTARTSYS;
    if (ret == 0) // a timeout
        return -EIO;mydev->pcm->streams[0].substream->dma_buffer 
    dbg("Finished a DMA read");
    return read_ret;
}
*/

/*
    DMA design
    Interrupts are triggered only after submitting a descriptor
    Hence, once capturing started issue a read in a descriptor triggering an IRQ in a while loop exiting if trigger was requested
    IF this does not work as intended, than a timer is required which will trigger a read at a fixed sample interval
    Once the IRQ is fired (because descriptor was issued to HW) reassert IRQ's and continue with the while loop

*/
static irqreturn_t dma_snd_irq_handler(int irq, void* dev_id)
{
    struct msgdma_data* data = (struct msgdma_data*)dev_id;
    struct msgdma_reg* msgdma0_reg = data->msgdma0_reg;

    dbg("DMA device status interrupt %x ", msgdma0_reg->csr_status);
    /* Acknowledge corresponding DMA and wake up whoever is waiting */
    if (ioread32(&msgdma0_reg->csr_status) & IRQ)
    {
        setbit_reg32(&msgdma0_reg->csr_status, IRQ);
        if (!data->running)
            goto __eexit;


   //     dbg("Interrupt ackonwledged!");
        snd_pcm_period_elapsed(data->substream);
        //data->rd_in_progress = 0; // this will wake up the read function waiting on the queue
        //wake_up_interruptible(&data->rd_complete_wq);
    }

//    dbg("Interrupt end!");
__eexit:
    return IRQ_HANDLED;
}

static int dma_snd_register_chrdev(struct msgdma_data* data) // TODO: do we need a char dev? I think a misc device suffices - then some changes have to be made (opening etc?)
{
    int ret = 0;
    struct device* dev;

    ret = alloc_chrdev_region(&data->dev_id, 0, 1, DEV_NAME);
    if (ret < 0)
    {
        pr_err("character device region allocation failed");
        goto __error;
    }
    // Create a class in sysfs to be mounted by udev
    if (IS_ERR(data->cl = class_create(THIS_MODULE, "chrdev")))
    {
        pr_err("character class creation failed");
        goto __chrdev_add_err;
    }
    if (IS_ERR(dev = device_create(data->cl, NULL, data->dev_id, NULL, "dma_snd")))
    {
        pr_err("character device creation failed");
        class_destroy(data->cl);
        goto __chrdev_add_err;
    }
    // Actual registering of the device 
    cdev_init(&data->cdev, &dma_snd_fops);
    ret = cdev_add(&data->cdev, data->dev_id, 1);
    if (ret < 0)
    {
        pr_err("character device initialization failed");
        device_destroy(data->cl, data->dev_id);
        class_destroy(data->cl);
        goto __chrdev_add_err;
    }

    return 0;
__chrdev_add_err:
    unregister_chrdev_region(data->dev_id, 1);
__error:
    return ret;
}

static void dma_snd_unregister_chrdev(struct msgdma_data* data)
{
    cdev_del(&data->cdev);
    device_destroy(data->cl, data->dev_id);
    class_destroy(data->cl);
    unregister_chrdev_region(data->dev_id, 1);
}

/* Main functions */
static int dma_snd_probe(struct platform_device* pdev)
{
    struct msgdma_data* data;
    struct resource* res;
    struct resource* region;
    struct device* dev;

    struct snd_card* card;
    int nr_subdevs = 1; // how many capture substreams (by default just 1)
    struct snd_pcm* pcm;
    //int dev_id = pdev->id;
    int ret = 0;

    dbg("DMA_SND Probe entered");

    dev = &pdev->dev;
    
    /* ALSA part */
    // for now separately allocate dma and alsa stuff, then think about merging it
    ret = snd_card_new(dev, 3, "FPGA Synthesizer Card", THIS_MODULE, sizeof(struct msgdma_data), &card);
    if (ret < 0)
        goto __nodev;

    data = card->private_data;
    data->card = card;
    // MUST have mutex_init here, else crash on mutex_lock
    mutex_init(&data->cable_lock);

    dbg("DMA_SND data %p dev_id %d", data, pdev->id);

    strcpy(card->driver, "dma_snd_driver");
    sprintf(card->shortname, "FPGA Synthesizer %s", DEV_NAME);
    strcpy(card->longname, card->shortname);

    dbg("DMA_SND card names copying success");
    ret = snd_device_new(card, SNDRV_DEV_LOWLEVEL, data, &snd_dev_ops);
    if (ret < 0)
        goto __nodev;
    /* 0 playback, 1 capture substreams  */
    ret = snd_pcm_new(card, card->driver, 0, 0, nr_subdevs, &pcm);
    if (ret < 0)
        goto __nodev;

    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_CAPTURE, &dma_snd_pcm_ops);
    pcm->private_data = data; // it should be the dev/card struct (the one containing snd_card* card) -> this will not end up in substream->private_data
    pcm->info_flags = 0;
    strcpy(pcm->name, card->shortname);
    dbg("DMA_SND snd_pcm_set_ops success");

    /* Prepare DMA buffers */
   // dma_set_coherent_mask(&pdev->dev, DMA_BIT_MASK(32)); // equal to the data width in IP component

    // in the minivosc there is a mention of mydev->substream->private_data = data;
    // which crashes, so they moved handling this to _open

/*
    ret = snd_pcm_lib_preallocate_pages_for_all(pcm, // TODO: this has to be changed and made coherent with DMA from the FPGA
            SNDRV_DMA_TYPE_CONTINUOUS,
            snd_dma_continuous_data(GFP_KERNEL),
            DMA_BUF_SIZE, DMA_BUF_SIZE);

    dbg("DMA_SND snd_pcm_lib_preallocate success");
    if (ret < 0)
        goto __nodev;
*/

    ret = snd_card_register(card);
    if (ret < 0)
        goto __nodev;

    /* DMA part */

    platform_set_drvdata(pdev, (void*)data);

    data->dma_buf_rd = dma_alloc_coherent(
        dev,
        DMA_BUF_SIZE,
        &data->dma_buf_rd_handle,
        GFP_KERNEL);

    if (data->dma_buf_rd == NULL)
    {
        ret = -ENOMEM;
        goto __fail;
    }

    /* Remap IO region of the device */
    /* Obtain the resource structure containing start, end and IO memory size */
    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (res == NULL)
    {
        dev_err(&pdev->dev, "io region resource not defined");
        return -ENODEV;
    }

    /* Request the region from the memory to guarantee exclusiveness */
    region = devm_request_mem_region(
        dev,
        res->start,
        resource_size(res),
        dev_name(dev));
    if (region == NULL)
    {
        dev_err(dev, "mem region not requested");
        return -EBUSY;
    }

    /* Map the region to memory */
    data->msgdma0_reg = devm_ioremap_nocache(dev, region->start, MSGDMA_MAP_SIZE);
    if (data->msgdma0_reg <= 0)
    {
        dev_err(dev, "could not remap io region");
        return -EFAULT;
    }

    /* Initialize the device itself */
    dma_snd_reset(data->msgdma0_reg);
    setbit_reg32(&data->msgdma0_reg->csr_ctrl,
        STOP_ON_EARLY_TERM | STOP_ON_ERR | GLOBAL_IRQ_EN);

    /* Get device's IRQ number(s) */
    data->msgdma0_irq = platform_get_irq(pdev, 0);
    if (data->msgdma0_irq < 0)
    {
        pr_err("could not get irq number");
        return -ENXIO;
    }

    ret = devm_request_irq(dev, data->msgdma0_irq, dma_snd_irq_handler, IRQF_SHARED, "msgdma0", data);
    if (ret < 0)
    {
        dev_err(dev, "could not request irq %d", data->msgdma0_irq);
        return ret;
    }

    data->rd_in_progress = 0;
    init_waitqueue_head(&data->rd_complete_wq);


    ret = dma_snd_register_chrdev(data); // TODO: remove char device totally, leave this driver just as an ALSA soundcard!!!
    if (ret < 0)
        return ret;
    
    dbg("DMA Probe exit");
    return 0;


__nodev:
    dbg("__nodev reached!!");
    snd_card_free(card); // this will call .dev_free registerd func

__fail:
    dbg("__fail reached!!");
    dma_snd_remove(pdev);
    return ret;
}

static int dma_snd_remove(struct platform_device* pdev)
{
    struct msgdma_data* data = (struct msgdma_data*)platform_get_drvdata(pdev);

    snd_card_free(data->card);
    
    dma_snd_unregister_chrdev(data); // TODO: check if a char device will be useful for JACK
    dma_free_coherent(
        &pdev->dev,
        DMA_BUF_SIZE,
        data->dma_buf_rd,
        data->dma_buf_rd_handle);
    return 0;
}

static int __init dma_snd_init(void)
{
    return platform_driver_register(&dma_snd_driver);
}

static void __exit dma_snd_exit(void)
{
    platform_driver_unregister(&dma_snd_driver);
}

// if using subsys_initcall dma cannot be a LKM
subsys_initcall(dma_snd_init);
module_exit(dma_snd_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jakub Duchniewicz, j.duchniewicz@gmail.com");
MODULE_DESCRIPTION("DMA receiver driver acting as ALSA Hardware Source");
MODULE_VERSION("1.0");