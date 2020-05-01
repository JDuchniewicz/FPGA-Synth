#! /usr/bin/bash
./build_makesd.sh
# TODO: when script fails, retry until success
echo "Copying image to device"
sudo dd if=sdcard_cv.img of=/dev/mmcblk0 bs=2048
echo "Syncing"
sync

# maybe add also copying required stuff from kernel
