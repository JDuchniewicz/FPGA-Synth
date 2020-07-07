#include <stdio.h>
#include <signal.h>
#include <poll.h>
#include <alloca.h>
#include <alsa/asoundlib.h>

static snd_seq_t* seq;
static snd_seq_addr_t* port;
static volatile sig_atomic_t stop = 0;
static int fpga_fd = 0;

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

static void check_snd(const char* operation, int err)
{
    if (err < 0)
        fatal("Cannot %s - %s", operation, snd_strerror(err));
}

static void mem_check(void* p)
{
    if(!p)
        fatal("Out of memory");
}

static void init_seq(void)
{
    int err;
    // open sequencer for reading
    err = snd_seq_open(&seq, "default", SND_SEQ_OPEN_DUPLEX, 0); //TODO: check which direction
    check_snd("open sequencer", err);

    err = snd_seq_set_client_name(seq, "keyboard");
    check_snd("set client name", err);
}

static void create_port(void)
{
    int err;
    err = snd_seq_create_simple_port(seq, "keyboard",
                                     SND_SEQ_PORT_CAP_WRITE |
                                     SND_SEQ_PORT_CAP_SUBS_WRITE,
                                     SND_SEQ_PORT_TYPE_MIDI_GENERIC |
                                     SND_SEQ_PORT_TYPE_APPLICATION);
    check_snd("create port", err);
}

static void connect_port(void)
{
    int err;
    err = snd_seq_connect_from(seq, 0, port->client, port->port); // 0 because we do not specify outgoing port, we just print info right now!!!!
    if (err < 0)
        fatal("Cannot connect from port %d:%d - %s",
              port->client, port->port, snd_strerror(err));
}

static unsigned int create_fpga_command(int on, unsigned char note, unsigned char velocity)
{
    unsigned int command = 0x0;
    command |= note;
    command <<= 8;
    command |= velocity;
    command |= (on << 15); // the order is important because of the types
    //printf("Command is: %x\n", command);
    return command;
}

static void write_device(unsigned int* command)
{
    printf("Writing a command %x to the /dev/synthesizer\n", *command);
    if (write(fpga_fd, command, sizeof(unsigned int)) < sizeof(unsigned int))
        fatal("Could not write command %x to the /dev/synthesizer\n", *command);
}

// This function has to command the FPGA firstly decoding the note into the most important parts
// Commands should be truncated and concatenated into appropriate messages to be sent to the driver, which will then transfer the commands to the char file
// moreover interrupt should be signalled to start/stop whole pipeline of substractive synthesis
// should this userspace application obtain this audio via DMA and output it somewhere or should it be done only in driver - which will then supply it to any application that waits for it?
static void handle_event(snd_seq_event_t* ev)
{
    unsigned int command = 0x0;
    printf("%3d:%-3d ", ev->source.client, ev->source.port);
    switch (ev->type) {
        case SND_SEQ_EVENT_NOTEON:
            if (ev->data.note.velocity)
            {
                printf("Note on             %2d, note %d, velocity %d\n",
                       ev->data.note.channel, ev->data.note.note, ev->data.note.velocity);
                // write to FPGA
               command = create_fpga_command(1, ev->data.note.note, ev->data.note.velocity);
               write_device(&command);
            }
            else // never triggers?
            {
                printf("Note off             %2d, note %d",
                       ev->data.note.channel, ev->data.note.note);
               command = create_fpga_command(0, ev->data.note.note, 0x0);
               write_device(&command);
            }
            break;
        case SND_SEQ_EVENT_NOTEOFF:
        {
            printf("Note off %2d, note %d, velocity %d\n",
                    ev->data.note.channel, ev->data.note.note, ev->data.note.velocity);
            command = create_fpga_command(0, ev->data.note.note, ev->data.note.velocity);
            write_device(&command);
            break;
        }
        default:
            printf("Event type: %d\n", ev->type);
    }
}

int main(int argc, char* argv[])
{
    int err;
    struct pollfd* pfds;
    int npfds;
    if (argc < 2) // argv[1] is the port num to listen on
        fatal("Please pass a port to listen on!\n");

    // open FPGA device file
    fpga_fd = open("/dev/synthesizer", O_WRONLY);
    if (fpga_fd < 0)
        fatal("Could not open the FPGA char file!\n");

    // initialize the sequencer object
    init_seq();

    // choose appropriate port for reading from, firstly allocating buffer for returned addr
    port = realloc(port, sizeof(snd_seq_addr_t));
    mem_check(port);

    err = snd_seq_parse_address(seq, port, argv[1]);
    if (err < 0)
        fatal("Invalid port %s - %s", argv[1], snd_strerror(err));

    // create the port object
    create_port();

    // connect the port object to the sequencer - in this case we just connect to a dummy output port
    connect_port();
    // set the non-block mode so that the client won't go to sleep once it fills the queue of sequencer with events
    err = snd_seq_nonblock(seq, 1);
    check_snd("set nonblock mode", err);

    printf("Waiting for data at port %d:0.", snd_seq_client_id(seq));
    printf(" Press Ctrl+C to end.\n");
    printf("Source Event                Ch  Data\n");

    signal(SIGINT, sighandler);
    signal(SIGSTOP, sighandler);

    npfds = snd_seq_poll_descriptors_count(seq, POLLIN);
    pfds = alloca(sizeof(*pfds) * npfds);

    // sequencer obtains event from fd's associated with it, we must allocate
    // space in userspace for them and then obtain data from them which is then handled
    // loop terminates on any error or interrupt signal
    for (;;)
    {
        snd_seq_poll_descriptors(seq, pfds, npfds, POLLIN);
        if (poll(pfds, npfds, -1) < 0)
            break;
        do {
            snd_seq_event_t* event;
            err = snd_seq_event_input(seq, &event);
            if (err < 0)
                break;
            if (event)
                handle_event(event);
        } while (err > 0);
        fflush(stdout);
        if (stop)
            break;
    }
    
    close(fpga_fd);
    snd_seq_close(seq);
    return 0;
}