#!/usr/bin/env python

import sys
import errno

import zmq
import time

ZMQ_ADDRESS = sys.argv[1]
QUEUE_SIZE = int(sys.argv[2])

context = zmq.Context()
client = context.socket(zmq.PUSH)
client.setsockopt(zmq.SNDHWM, QUEUE_SIZE)
client.setsockopt(zmq.RCVHWM, QUEUE_SIZE)
client.setsockopt(zmq.BACKLOG, QUEUE_SIZE)
client.connect(ZMQ_ADDRESS)

for total in xrange(1000000000):
    try:
        if total % 100000 == 0:
            print total, "messages sent"
            time.sleep(1)

        filename = "/tmp/filename.%d.log" % (total / 10000)
        client.send("%s\tMessage #%d\n" % (filename, total), zmq.NOBLOCK)
    except zmq.core.error.ZMQError, e:
        if e.errno == errno.EAGAIN:
            print "Outgoing queue if full"
        else:
            print "ZMQError:", str(e)
    except Exception, e:
        print "Exception:", str(e)

