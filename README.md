# LogXY
Logger service simple as this.

It is based on ZeroMQ and waits for **messages in format: [filename]\t[message]**.

You can use it from any language that has ZeroMQ library binding.

*Yes, @epikhinm, you should pass filename with each message. :)*

*But it is dead simple and cheap for IPC transport.*

*And I'm open to ideas how to make it more efficiant and simple.*


Inspiration or why not syslog (rsyslog)?
--
I already asked that question to myself when I needed some logging in simple multiprocess uwsgi app.

I face several problems:

1. I need multiline logging - to enable this I should change global option. I dont want to change global options, because I don't want to break real system logs.
2. No time prefix for log line, and no special characters in beginning of message by specifying template like that: $template myFormat,"%msg:2:1048576%\n"
3. I have a lot of logs on one app, so I wrote about 15 regexps to forward them in different files.
4. Fighting with limitation for size of single syslog message.
5. Problem with syslog function deadlock when syslogd cannot handle so much logs.

Oh, no.

I need just a simple thing: to write logs consistently, use queue on client and server sides to not to wait on system cache flushes.

So I thought that I can write such service in one evening.

Build
--
Install **libzmq** >= 3.2: you can take it here https://github.com/zeromq/libzmq or if you have it in repositories, just install it using apt-get, yum, port, brew or whatever.

And run **make**.

Usage
--
Just run: 
```
logxy <ZEROMQ_SOCKET_ADDRESS> <MAX_QUEUE_SIZE> <PID_FILENAME>
```

If you use it on one machine - use unix socket as a transport.
For example: 
```
logxy ipc:///tmp/logxy.sock 1000000 /var/run/logxy.pid
```

Example
--
Run logxy: 
```
logxy ipc:///tmp/logxy.sock 1000000 /var/run/logxy.pid
```

And run example/client.py: 
```
client.py ipc:///tmp/logxy.sock 1000000
```

Second argument of client is outgoing queue size for buffering messages.

Benchmarks
--
I've tested in on single RHEL-server with unix-socket as a transport.

So, in that case LogXY is bounded by message rate (~300K per second) and Disk IO (100 Mb/s in my case).

# Dependencies
Beautiful ZeroMQ library: **libzmq** >= 3.2 (https://github.com/zeromq/libzmq)

Python bindings to ZeroMQ for running example: **pyzmq** (https://github.com/zeromq/pyzmq)

Remarks
--
Now that code is going to production.

We made a bet with @brk0v that after a month of usage code will **grow more than 100 lines**. 

Now there is **229 lines of code**.

If it will be so I will buy @brk0v a cup of hot black tea in Starbucks.

It not - he will buy me a cup of hot chocolate. ;)

PS
--
Thanks to @epikhinm (https://github.com/epikhinm) and @brk0v (https://github.com/brk0v) for trolling me. :)

Sometimes it motivates.
