#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>

#define BUFFER_SIZE 4096 

static volatile sig_atomic_t stop = 0;
static int dma_snd_fd = 0;

static void fatal(const char* msg, ...)
{
    va_list ap;
    va_start(ap, msg);
    vfprintf(stderr, msg, ap);
    va_end(ap);
    fputc('\n', stderr);
    exit(EXIT_FAILURE);
}

static void sighandler(int sig)
{
    stop = 1;
}

int main(int argc, char* argv[])
{
    int* buffer = NULL; // a buffer of 32 bit values
    FILE* destination;
    ssize_t bytes;
    dma_snd_fd = open("/dev/dma_snd", O_RDONLY);
    destination = fopen("/root/tempfile", "w+");
    if (!destination)
        fatal("Could not open the destination file! errno: %d", errno);
    if (dma_snd_fd < 0)
        fatal("Could not open the DMA_SND char file, errno: %d!", errno);

    signal(SIGINT, sighandler);
    signal(SIGSTOP, sighandler);

    buffer = malloc(BUFFER_SIZE);
    for (;;)
    {
        bytes = read(dma_snd_fd, buffer, BUFFER_SIZE);
        //printf("Reading %d bytes\n", bytes);
        if (bytes < 0)
        {
            free(buffer);
            close(dma_snd_fd);
            fatal("Could not read from the file, errno: %d!", errno);
        }
        if (bytes == 0)
        {
            free(buffer);
            close(dma_snd_fd);
            fatal("DMA buffer is now empty\n");
        }
        fwrite(buffer, sizeof(int), bytes, destination);

        /*
        for (int i = 0; i < bytes; ++i)
        {
            printf("%d | %x \t", i, *(buffer + i));
        }
        */
        printf("\n\n");

        if (stop)
            break;
    }
    close(dma_snd_fd);
    return 0;
}