#include "dma_snd.h"

// utility functions for bitmasks setting
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

static ssize_t dma_snd_read(struct file* f, char __user* ubuf, size_t len, loff_t* off)
{
    struct msgdma_data* data;
    dma_addr_t read_addr;
    size_t to_read;
    ssize_t read_ret;
    int ret;

    pr_info("Starting a DMA read\n");
    data = (struct msgdma_data*)f->private_data;
    read_ret = len > DMA_BUF_SIZE ? DMA_BUF_SIZE : len;
    to_read = read_ret;

    /* Start transfer */
    read_addr = data->dma_buf_rd_handle;
    while (to_read > MSGDMA_MAX_TX_LEN)
    {
        dma_snd_push_descr( // check parameter order ( I think read is mixed with write)
            data->msgdma0_reg,
            0,
            read_addr,
            MSGDMA_MAX_TX_LEN,
            0);

        to_read -= MSGDMA_MAX_TX_LEN;
        read_addr += MSGDMA_MAX_TX_LEN;
        pr_info("Reading bytes to_read: %d read_addr: %d\n", to_read, read_addr);
    }
    /* Last descriptor sends an IRQ */
    dma_snd_push_descr(
        data->msgdma0_reg,
        0,
        read_addr, // write to the "read"
        to_read,
        TX_COMPL_IRQ_EN);
    pr_info("Done reading bytes to_read: %d read_addr: %d\n", to_read, read_addr);
    
    /* Wait for the transferto complete */
    ret = wait_event_interruptible_timeout(
        data->rd_complete_wq,
        !data->rd_in_progress,
        TX_TIMEOUT);
    
    if (ret < 0)
        return -ERESTARTSYS;
    if (ret == 0) // a timeout
        return -EIO;
    if (copy_to_user(ubuf, data->dma_buf_rd, read_ret) != 0)
        return -EFAULT;
    
    pr_info("Finished a DMA read\n");
    return read_ret;
}

static int dma_snd_register_chrdev(struct msgdma_data* data) // TODO: do we need a char dev? I think a misc device suffices - then some changes have to be made (opening etc?)
{
    int ret = 0;

    ret = alloc_chrdev_region(&data->dev_id, 0, 1, DEV_NAME);
    if (ret < 0)
    {
        pr_err("character device region allocation failed\n");
        goto error;
    }
    /* Actual registering of the device */
    cdev_init(&data->cdev, &dma_snd_fops);
    ret = cdev_add(&data->cdev, data->dev_id, 1);
    if (ret < 0)
    {
        pr_err("character device initialization failed\n");
        goto chrdev_add_err;
    }

    return 0;
chrdev_add_err:
    unregister_chrdev_region(data->dev_id, 1);
error:
    return ret;
}

static void dma_snd_unregister_chrdev(struct msgdma_data* data)
{
    cdev_del(&data->cdev);
    unregister_chrdev_region(data->dev_id, 1);
}

static irqreturn_t dma_snd_irq_handler(int irq, void* dev_id)
{
    struct msgdma_reg* msgdma0_reg;
    struct msgdma_data* data = (struct msgdma_data*)dev_id;
    msgdma0_reg = data->msgdma0_reg;

    /* Acknowledge corresponding DMA and wake up whoever is waiting */
    if (ioread32(&msgdma0_reg->csr_status) & IRQ)
    {
        setbit_reg32(&msgdma0_reg->csr_status, IRQ);
        data->rd_in_progress = 0; // this will wake up the read function waiting on the queue
        wake_up_interruptible(&data->rd_complete_wq);
    }

    return IRQ_HANDLED;
}

static int dma_snd_probe(struct platform_device* pdev)
{
    struct msgdma_data* data;
    struct resource* res;
    struct resource* region;
    struct device* dev;
    int ret = 0;

    pr_info("DMA Probe entered\n");
    dev = &pdev->dev;

    data = (struct msgdma_data*)devm_kzalloc(dev, sizeof(*data), GFP_KERNEL);
    if (data == NULL)
        return -ENOMEM;

    platform_set_drvdata(pdev, (void*)data);

    /* Prepare DMA buffers */
    dma_set_coherent_mask(&pdev->dev, DMA_BIT_MASK(32)); // equal to the data width in IP component

    data->dma_buf_rd = dma_alloc_coherent(
        dev,
        DMA_BUF_SIZE,
        &data->dma_buf_rd_handle,
        GFP_KERNEL);

    if (data->dma_buf_rd == NULL)
    {
        ret = -ENOMEM;
        goto fail;
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

    ret = dma_snd_register_chrdev(data);
    if (ret < 0)
        return ret;
    
    pr_info("DMA Probe exit\n");
    return 0;
fail:
    dma_snd_remove(pdev);
    return ret;
}

static int dma_snd_remove(struct platform_device* pdev)
{
    struct msgdma_data* data = (struct msgdma_data*)platform_get_drvdata(pdev);

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