#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/uaccess.h>

static int leds_probe(struct platform_device* pdev);
static int leds_remove(struct platform_device* pdev);
static ssize_t leds_read(struct file* file, char* buffer, size_t len, loff_t* offset);
static ssize_t leds_write(struct file* file, const char* buffer, size_t len, loff_t* offset);

// An instance of this struct will be created for each custom_led IP in the system
struct custom_leds_dev {
    struct miscdevice miscdev;
    void __iomem* regs;
    u8 leds_value;
};

static struct of_device_id custom_leds_dt_ids[] = {
    {
        .compatible = "dev,custom-leds"
    }, 
    { /* end of table */ }
};

// inform the kernel which devices are supported by this driver
MODULE_DEVICE_TABLE(of, custom_leds_dt_ids);

// data structure to link our driver with probe and remove functions
static struct platform_driver leds_platform = {
    .probe = leds_probe,
    .remove = leds_remove,
    .driver = {
        .name = "Custom LEDs Driver",
        .owner = THIS_MODULE,
        .of_match_table = custom_leds_dt_ids
    }
};

// File operations that can be performed on the custom_leds character_file
static struct file_operations custom_leds_fops = {
    .owner = THIS_MODULE,
    .read = leds_read,
    .write = leds_write
};

// Called when the driver is initialized
static int leds_init(void)
{
    int ret_val = 0;
    pr_info("Initializing the custom LEDs module\n");

    // register our driver with the "Platform Driver" bus
    ret_val = platform_driver_register(&leds_platform);
    if (ret_val != 0) {
        pr_err("platform_driver_register returned %d\n", ret_val);
        return ret_val;
    }

    pr_info("Custom LEDs moduler properly initialized!\n");
    return 0;
}

// Called whenever the kernel finds a new device our driver can handle (in this case only once (at initialisation))
static int leds_probe(struct platform_device* pdev)
{
    int ret_val = -EBUSY;
    struct custom_leds_dev* dev;
    struct resource* r = 0;

    pr_info("leds_probe enter\n");

    // get memory resources for this LED device
    r = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (r == NULL) {
        pr_err("IORESOURCE_MEM (register space) does not exist!\n");
        goto bad_exit_return;
    }

    // create structure to hold device specific information(like the registers)
    dev = devm_kzalloc(&pdev->dev, sizeof(struct custom_leds_dev), GFP_KERNEL);
    
    // both request and ioremap a memory region
    // this makes sure nobody will grab this memory region
    // and moves to our address space so that we can use it
    dev->regs = devm_ioremap_resource(&pdev->dev, r);
    if (IS_ERR(dev->regs))
        goto bad_ioremap;

    // turn the LEDs on (access the 0th register in the custom leds module)
    dev->leds_value = 0xFF;
    iowrite32(dev->leds_value, dev->regs);
    
    // Initialize the misc device (this is used to create a character file in userspace)
    dev->miscdev.minor = MISC_DYNAMIC_MINOR;
    dev->miscdev.name = "custom_leds";
    dev->miscdev.fops = &custom_leds_fops;

    ret_val = misc_register(&dev->miscdev);
    if (ret_val != 0) {
        pr_info("Could not register misc device\n");
        goto bad_exit_return;
    }

    // give a pointer to the instance-specific data to the generic platform_device structure
    // we can access this data later on (e.g. read and write functions)
    platform_set_drvdata(pdev, (void*)dev);

    pr_info("leds_probe exit");

    return 0;
bad_ioremap:
    ret_val = PTR_ERR(dev->regs);
bad_exit_return:
    pr_info("leds_probe bad exit\n");
    return ret_val;
}

// This function is called whenever a read operation occurs on one of character files
static ssize_t leds_read(struct file* file, char* buffer, size_t len, loff_t* offset)
{
    int success = 0;

    // misc subsystem has its own open function that will set file's private data to the 
    // apropriate miscdevice structure
    struct custom_leds_dev* dev = container_of(file->private_data, struct custom_leds_dev, miscdev);
    // give user the current led value
    success = copy_to_user(buffer, &dev->leds_value, sizeof(dev->leds_value));
    if (success != 0) {
        pr_info("Failed to return the current led value to userspace\n");
        return -EFAULT; //Bad address retval, probably the pointer to buffer was rubbbish
    }

    return 0; //'0' indicates EOF, userspace process will stop reading now
}

static ssize_t leds_write(struct file* file, const char* buffer, size_t len, loff_t* offset)
{
    int success = 0;

    struct custom_leds_dev* dev = container_of(file->private_data, struct custom_leds_dev, miscdev);
    // get the new led value(just the first byte of given data)
    success = copy_from_user(&dev->leds_value, buffer, sizeof(dev->leds_value));
    if (success != 0) {
        pr_info("Failed to copy the current led value from userspace\n");
        return -EFAULT; //Bad address retval, probably the pointer to buffer was rubbbish
    } else {
        // we read the data correclty, so update LEDs
        iowrite32(dev->leds_value, dev->regs);
    }

    // tell the user process we wrote all their data, even though we read only first byte, it will stop them from resending it over again
    return len;
}

// gets called whenever a device this driver handles is removed
// this will also be called for each handled device when our driver is 
// removed with rmmod command
static int leds_remove(struct platform_device* pdev)
{
    // grab instance specific info out of platform_device
    struct custom_leds_dev* dev = (struct custom_leds_dev*)platform_get_drvdata(pdev);
    pr_info("leds_remove enter\n");
    // turn the LEDs off
    iowrite32(0x00, dev->regs);
    //unregister character device file (remove it from /dev)
    misc_deregister(&dev->miscdev);
    pr_info("leds_remove exit\n");
    return 0;
}

// called when driver is removed
static void leds_exit(void)
{
    pr_info("Custom LEDs module exit\n");

    // unregister our driver from the "Platform Driver" bus
    // this will in turn call leds_remove for each connected device
    platform_driver_unregister(&leds_platform);

    pr_info("Custom LEDs module successfully unregistered\n");
}

module_init(leds_init);
module_exit(leds_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("TWOJA STARA");
MODULE_DESCRIPTION("Custom leds controlling module");
MODULE_VERSION("1.0");