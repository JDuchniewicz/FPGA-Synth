TARGET = midi_control

CFLAGS = -static -g -Wall -std=gnu99 -I/home/jduchniewicz/Projects/De0Nano/atlas_linux_ghrd/software/buildroot/output/build/alsa-lib-1.1.9/include 
LDFLAGS = -g -Wall -L/home/jduchniewicz/Projects/De0Nano/atlas_linux_ghrd/software/buildroot/output/target/usr/lib/ -lasound
CC = $(CROSS_COMPILE)gcc
ARCH = arm

build: $(TARGET)
$(TARGET): $(TARGET).o
	$(CC) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(TARGET) *.a *.o *.~