#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/uaccess.h>

static int synthesizer_probe(struct platform_device* pdev);
static int synthesizer_remove(struct platform_device* pdev);
//static ssize_t leds_read(struct file* file, char* buffer, size_t len, loff_t* offset);
//static ssize_t leds_write(struct file* file, const char* buffer, size_t len, loff_t* offset);

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
    // values to be filled later/ probably many GPIO's
   // u8 leds_value;
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
static struct file_operations custom_leds_fops = {
    .owner = THIS_MODULE,
    .read = leds_read,
    .write = leds_write
};

// Called when the driver is initialized
static int leds_init(void)
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
static void leds_exit(void)
{
    pr_info("DSP Audio Synthesis module exit\n");

    // unregister our driver from the "Platform Driver" bus
    // this will in turn call leds_remove for each connected device
    platform_driver_unregister(&synthesizer_platform);

    pr_info("DSP Audio Synthesis module successfully unregistered\n");
}

module_init(synthesizer_init);
module_exit(synthesizer_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jakub Duchniewicz, j.duchniewicz@gmail.com");
MODULE_DESCRIPTION("Digital Signal Processing Audio Synthesis driver for FPGA control");
MODULE_VERSION("1.0");