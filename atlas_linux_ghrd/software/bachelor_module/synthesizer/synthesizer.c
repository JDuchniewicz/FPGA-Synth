#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/uaccess.h>

static int synthesizer_probe(struct platform_device* pdev);
static int synthesizer_remove(struct platform_device* pdev);
static ssize_t synthesizer_write(struct file* file, const char* buffer, size_t len, loff_t* offset);

/*
    MODULE DETAILS
    Name: synthesizer
    I/O: GPIOs?
    Required functions: start(write)/stop(write and read?)

    This module will be responsible for issuing FPGA for DSP and outputing result to be played by audio userspace systems

*/

// An instance of this struct will be created for each synthesizer IP in the system
struct synthesizer_dev {
    struct miscdevice miscdev;
    void __iomem* regs;

    u32 command_value; // command value to send via AVALON MM interface
};

static struct of_device_id synthesizer_dt_ids[] = {
    {
        .compatible = "dev,synthesizer"
    }, 
    { /* end of table */ }
};

// inform the kernel which devices are supported by this driver
MODULE_DEVICE_TABLE(of, synthesizer_dt_ids);

// data structure to link our driver with probe and remove functions
static struct platform_driver synthesizer_platform = {
    .probe = synthesizer_probe,
    .remove = synthesizer_remove,
    .driver = {
        .name = "DSP Audio Synthesis Driver",
        .owner = THIS_MODULE,
        .of_match_table = synthesizer_dt_ids
    }
};

// File operations that can be performed on the custom_leds character_file
static struct file_operations synthesizer_fops = {
    .owner = THIS_MODULE,
    .write = synthesizer_write,
};

// Called whenever a write is made to the /dev/synthesizer character device
static ssize_t synthesizer_write(struct file* file, const char* buffer, size_t len, loff_t* offset)
{
    int success = 0;
    struct synthesizer_dev* dev = container_of(file->private_data, struct synthesizer_dev, miscdev);

    pr_info("Writing to the device\n");

    success = copy_from_user(&dev->command_value, buffer, sizeof(dev->command_value));
    if (success != 0)
    {
        pr_info("Failed to copy the MIDI command from userspace\n");
        return -EFAULT;
    } else 
    {
        iowrite32(dev->command_value, dev->regs);
        pr_info("Finished writing to the device: data %d\n", dev->command_value);
    }

    // inform the userspace we wrote all the data
    return len;
}

// Called whenever the kernel finds a new device our driver can handle (in this case only once (at initialisation))
static int synthesizer_probe(struct platform_device* pdev)
{
    int ret_val = -EBUSY;
    struct synthesizer_dev* dev;
    struct resource* r = 0;

    pr_info("synthesizer_probe enter\n");

    // get memory resources for this device
    r = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (r == NULL) {
        pr_err("IORESOURCE_MEM (register space) does not exist!\n");
        goto bad_exit_return;
    }

    // create structure to hold device specific information(like the registers)
    dev = devm_kzalloc(&pdev->dev, sizeof(struct synthesizer_dev), GFP_KERNEL);
    
    // both request and ioremap a memory region
    // this makes sure nobody will grab this memory region
    // and moves to our address space so that we can use it
    dev->regs = devm_ioremap_resource(&pdev->dev, r);
    if (IS_ERR(dev->regs))
        goto bad_ioremap;

    // initialize the value and zero out memory registers for MIDI command
    dev->command_value = 0x0000;
    iowrite32(dev->command_value, dev->regs);
    
    // Initialize the misc device (this is used to create a character file in userspace)
    dev->miscdev.minor = MISC_DYNAMIC_MINOR;
    dev->miscdev.name = "synthesizer";
    dev->miscdev.fops = &synthesizer_fops;

    ret_val = misc_register(&dev->miscdev);
    if (ret_val != 0) {
        pr_info("Could not register misc device\n");
        goto bad_exit_return;
    }

    // give a pointer to the instance-specific data to the generic platform_device structure
    // we can access this data later on (e.g. read and write functions)
    platform_set_drvdata(pdev, (void*)dev);

    pr_info("synthesizer_probe exit");

    return 0;
bad_ioremap:
    ret_val = PTR_ERR(dev->regs);
bad_exit_return:
    pr_info("synthesizer_probe bad exit\n");
    return ret_val;
}

// gets called whenever a device this driver handles is removed
// this will also be called for each handled device when our driver is 
// removed with rmmod command
static int synthesizer_remove(struct platform_device* pdev)
{
    // grab instance specific info out of platform_device
    struct synthesizer_dev* dev = (struct synthesizer_dev*)platform_get_drvdata(pdev);
    pr_info("synthesizer_remove enter\n");

    // issue STOP_ALL command
    iowrite32(0x7fff, dev->regs);

    //unregister character device file (remove it from /dev)
    misc_deregister(&dev->miscdev);
    pr_info("synthesizer_remove exit\n");
    return 0;
}

// Called when the driver is initialized
static int synthesizer_init(void)
{
    int ret_val = 0;
    pr_info("Initializing the DSP Audio Synthesis module\n");

    // register our driver with the "Platform Driver" bus
    ret_val = platform_driver_register(&synthesizer_platform);
    if (ret_val != 0) {
        pr_err("platform_driver_register returned %d\n", ret_val);
        return ret_val;
    }

    pr_info("DSP Audio Synthesis module properly initialized!\n");
    return 0;
}

// called when driver is removed
static void synthesizer_exit(void)
{
    pr_info("DSP Audio Synthesis module exit\n");

    // unregister our driver from the "Platform Driver" bus
    // this will in turn call synthesizer_remove for each connected device
    platform_driver_unregister(&synthesizer_platform);

    pr_info("DSP Audio Synthesis module successfully unregistered\n");
}

module_init(synthesizer_init);
module_exit(synthesizer_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jakub Duchniewicz, j.duchniewicz@gmail.com");
MODULE_DESCRIPTION("Digital Signal Processing Audio Synthesis driver for FPGA control");
MODULE_VERSION("1.0");