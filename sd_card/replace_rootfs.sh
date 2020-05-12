#!/usr/bin/bash
echo "Renaming old rootfs"
mv rootfs rootfs_old
mkdir rootfs

echo "Unpacking new rootfs"
tar -xvf ../software/buildroot/output/images/rootfs.tar -C ./rootfs
#sudo chown root:root ./rootfs is this step needed?
# copy the modules

echo "Copying kernel modules"
mkdir -p ./rootfs/lib/modules
sudo cp -R ./rootfs_old/lib/modules/* ./rootfs/lib/modules/
# For now it is empty... sudo cp ./rootfs_old/root/* ./rootfs/root/

echo "Moving SSH config files" # target needs 'haveged' package to create entropy faster, otherwise hangs on sshd startup
cp ./rootfs_old/etc/ssh/sshd_config ./rootfs/etc/ssh/sshd_config
echo "Moving Ethernet and sshd init fixes"
cp ./rootfs_old/etc/init.d/S99eth0 ./rootfs/etc/init.d/S99eth0
cp ./rootfs_old/etc/init.d/S49sshd-fix ./rootfs/etc/init.d/S49sshd-fix

echo "Removing old rootfs"
sudo rm -rf ./rootfs_old
