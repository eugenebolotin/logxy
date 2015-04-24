#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <chrono>
#include <csignal>
#include <string>

#include "zmqwrap.h"
#include "filecache.h"

const int POLL_TIMEOUT_MS = 100;
const int CACHE_CLEANUP_PERIOD_MS = 1000;

static bool stop = false;

int64_t GetTick()
{
    using namespace std::chrono;
    return duration_cast<milliseconds>(
            high_resolution_clock::now().time_since_epoch()).count();
}

void Message(const char* msg)
{
    printf("%s\n", msg);
}

void PrintUsage()
{
    printf("Usage: logxy 0MQ_SOCKET_ADDRESS MAX_QUEUE_SIZE PID_FILE_PATH\n");
}

void WritePid(const char* filename)
{
    FILE* file = fopen(filename, "w");
    if(!file)
    {
        Message("Cannot write pidfile");
        return;
    }
    fprintf(file, "%d", getpid());
    fclose(file);
}

void StopHandler(int)
{
    stop = true;
}

int main(int argc, char* argv[])
{
    if(argc != 4)
    {
        PrintUsage();
        return 1;
    }

    const char* socket_zmq = argv[1];
    size_t queue_size = atoi(argv[2]);
    const char* filename_pid = argv[3];

    WritePid(filename_pid);

    signal(SIGINT, StopHandler);
    signal(SIGTERM, StopHandler);
    signal(SIGHUP, SIG_IGN);

    zmqwrap::Context context(10);
    zmqwrap::Socket socket(context.Get(), ZMQ_PULL);
    zmq_setsockopt(socket.Get(), ZMQ_RCVHWM, &queue_size, sizeof(queue_size));
    zmq_setsockopt(socket.Get(), ZMQ_SNDHWM, &queue_size, sizeof(queue_size));
    zmq_setsockopt(socket.Get(), ZMQ_BACKLOG, &queue_size, sizeof(queue_size));
    zmq_bind(socket.Get(), socket_zmq);

    FileCache cache;
    int64_t lastclear_tick = GetTick();
    zmq_pollitem_t poll_items[] = {socket.Get(), 0, ZMQ_POLLIN, 0};

    while(!stop)
    {
        if(GetTick() - lastclear_tick > CACHE_CLEANUP_PERIOD_MS)
        {
            cache.Clear();
            lastclear_tick = GetTick();
        }


        if(zmq_poll(poll_items, 1, POLL_TIMEOUT_MS) != 1)
            continue;

        zmqwrap::Message msg;
        if(zmq_msg_recv(&msg.Get(), socket.Get(), 0) < 0)
        {
            Message("Cannot receive message");
            continue;
        }

        char* data = (char*)zmq_msg_data(&msg.Get());
        int data_size = (int)zmq_msg_size(&msg.Get());

        char* logdata = (char*)memchr(data, '\t', data_size);
        if(!logdata)
        {
            Message("Wrong message format");
            continue;
        }

        std::string filename(data, logdata - data);
        logdata++;

        FILE*& file = cache.Get()[filename];
        if(!file)
            file = fopen(filename.c_str(), "a");

        if(file)
            fwrite(logdata, data + data_size - logdata, 1, file);
    }

    Message("Process stopped");
    return 0;
}

