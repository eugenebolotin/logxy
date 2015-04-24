#ifndef ZMQWRAP_H
#define ZMQWRAP_H

#include <zmq.h>

namespace zmqwrap
{
    class Context
    {
        void* m_context;

    public:
        Context(int io_threads)
            : m_context(NULL)
        {
            m_context = zmq_ctx_new();
            zmq_ctx_set(m_context, ZMQ_IO_THREADS, io_threads);
        }

        void* Get()
        {
            return m_context;
        }

        ~Context()
        {
            if(m_context)
                zmq_ctx_destroy(m_context);
        }
    };

    class Socket 
    {
        void* m_socket;

    public:
        Socket(void* context, int type)
            : m_socket(NULL)
        {
            m_socket = zmq_socket(context, type);
        }

        void* Get()
        {
            return m_socket;
        }

        ~Socket()
        {
            if(m_socket)
                zmq_close(m_socket);
        }
    };

    class Message
    {
        zmq_msg_t m_msg;
    public:
        Message()
        {
            zmq_msg_init(&m_msg);
        }

        zmq_msg_t& Get()
        {
            return m_msg;
        }

        ~Message()
        {
            zmq_msg_close(&m_msg);
        }
    };
}

#endif
