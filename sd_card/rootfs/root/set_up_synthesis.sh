#!/bin/sh
echo "Setting up synthesis prerequisites"
echo "Loading ALSA modules"
modprobe snd-usb-audio
echo "Loading synthesis modules"
insmod synthesizer.ko

echo "Run aseqdump -l to find ports to listen"
echo "Run midi_control <port_num> to start synthesis"
