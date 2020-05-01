#!/usr/bin/bash
sudo rm -rf ./rootfs
mkdir rootfs
tar -xvf ../software/buildroot/output/images/rootfs.tar -C ./rootfs
sudo chown root:root ./rootfs
