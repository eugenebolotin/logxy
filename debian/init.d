#!/bin/sh
# -*- Encoding: utf-8 -*-
# kate: space-indent on; indent-width 4; replace-tabs on;
### BEGIN INIT INFO
# Provides:          logxy
# Required-Start:    $local_fs $network $remote_fs $syslog
# Required-Stop:     $local_fs $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Simple logger daemon that uses ZeroMQ as a transport
# Description:       LogXY is a simple logger daemon that uses ZeroMQ as a transport.
#                    It waits for messages in format: [filename]\t[message].
#                    message is any byte sequence. Only first tab is used as filename delimiter.
#                    You can use it from any language that has ZeroMQ library binding.
### END INIT INFO

# Author: Yaroslav Klimik <klimiky@yandex-team.ru>

# Do NOT "set -e"
RETVAL=0

PATH=/sbin:/usr/sbin:/bin:/usr/bin
ZEROMQ_SOCKET="ipc:///tmp/logxy.sock"
QUEUE_SIZE="1000000"
DESC="LogXY service"
NAME=logxy
DAEMON=/usr/sbin/logxy
PIDFILE=/var/run/$NAME.pid
LOGFILE=/var/log/logxy.log
LOCKFILE=/var/lock/logxy
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
#. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
#. /lib/lsb/init-functions

#
# Helper functions for beautifying output
#
RES_COL=60
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_WARNING="echo -en \\033[1;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

success() {
    local str=${1:-OK} s=" " l=0
    (( l=6-${#str}, l=l/2 ))
    ${MOVE_TO_COL}"["
    while [ $l -gt 0 ]; do s=" $s"; (( l-- )); done
    ${SETCOLOR_SUCCESS}"${s}$str"
    ${SETCOLOR_NORMAL}"$s]\r"
    return 0
}

failure() {
    local errstr=${1:-FAILED} s=" " l=0
    (( l=6-${#errstr}, l=l/2 ))
    ${MOVE_TO_COL}"["
    while [ $l -gt 0 ]; do s=" $s"; (( l-- )); done
    ${SETCOLOR_FAILURE}"${s}$errstr"
    ${SETCOLOR_NORMAL}"$s]\r"
    return 1
}

warning() {
    local warn=${1:-WARNING} s=" " l=0
    (( l=6-${#warn}, l=l/2 ))
    ${MOVE_TO_COL}"["
    while [ $l -gt 0 ]; do s=" $s"; (( l-- )); done
    ${SETCOLOR_WARNING}"${s}$warn"
    ${SETCOLOR_NORMAL}"$s]\r"
    return 1
}

#
# Functions that retrieves status of the daemon/service
#
check_server() {
    local PID MC
    if [ -f "$PIDFILE" ]; then
        PID=`cat ${PIDFILE}`
        if [ -n "$PID" ]; then
            MC=`ps ax | grep "${DAEMON}" | grep $PID | wc -l`
        fi
        if  [ $MC -gt 0 ]; then return 0
        elif [ $MC -eq 0 ]; then return 1; fi
    else
        MC=`ps ax | grep "${DAEMON}" | grep -v grep | wc -l`
        [ $MC -gt 0 ] && return 2
    fi
    return 3;
}

server_status() {
    check_server
    local RC=$?
    case "$RC" in
      0)
          local PID=`cat $PIDFILE`
          echo -e $"$DESC (process pid $PID) is \033[1;32mrunning\033[0;39m..."
          return 0
      ;;
      1)
          echo -e $"$DESC process is \033[1;31mdead\033[0;39m, but pid-file is present"
          return 1
      ;;
      2)
          echo -e $"$DESC process is still \033[1;31mprobably running\033[0;39m, but pid-file is \033[1;31mabsent\033[0;39m"
          return 2
      ;;
      3)
          echo -e $"$DESC server is \033[1;31mstopped\033[0;39m"
          return 0
      ;;
    esac
    echo -e $"$DESC server's status is \033[1;31mundetermined\033[0;39m"
    return 4
}

#
# Function that starts the daemon/service
#
do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running or another error
    #   2 if daemon could not be started
    [ -x $DAEMON ] || exit 2
    check_server
    local RC=$?
    if [ $RC -lt 3 ]; then
        echo "Warning: At least one instance of the server is already running. Will be started another instance!"
        RETVAL=1; failure; echo
    else
        echo -n "Starting $DESC server: "
        $DAEMON $ZEROMQ_SOCKET $QUEUE_SIZE $PIDFILE >$LOGFILE 2>&1 &
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            touch $LOCKFILE; success; RETVAL=0; echo
        else failure; RETVAL=1; echo
        fi
    fi
    return $RETVAL
}

#
# Function that stops the daemon/service
#
do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    check_server
    local RC=$?
    echo -n "Shutting down $DESC server: "
    if [ $RC -eq 0 ]; then
        local PID=`cat ${PIDFILE}`
        kill -TERM $PID > /dev/null 2>&1
        RETVAL=$?
        rm -f $PIDFILE
        [ $RETVAL -eq 0 ] && rm -f $LOCKFILE
        check_server; RC=$?
        if [ $RC -eq 3 ]; then success; RETVAL=0; else failure; RETVAL=2; fi
    elif [ $RC -eq 2 ]; then
        local INSTANCES=`ps ax | grep "$DAEMON" | grep -v grep | awk '{print $1}' | tr '\015\012' '  '`
        [ -n "$INSTANCES" ] && kill -KILL $INSTANCES >> $LOGFILE 2>&1
        check_server; RC=$?
        if [ $RC -eq 3 ]; then success; RETVAL=0; else failure; RETVAL=2; fi
    else
        [ -f "$PIDFILE" ] && rm -f $LOCKFILE $PIDFILE
        warning "Service is not running"; RETVAL=0
    fi; echo
    return $RETVAL
}

#
# Function that restarts the daemon/service
#
restart() {
    do_stop; RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        do_start; RETVAL=$?
    fi
}

case "$1" in
    start)
        do_start; RETVAL=$?
    ;;
    stop)
        do_stop; RETVAL=$?
    ;;
    status)
        server_status; RETVAL=$?
    ;;
    condrestart|try-restart|reload)
        exit 3
    ;;
    restart|force-reload)
        restart
    ;;
    *)
        echo "Usage: $(basename $0) {start|stop|restart|condrestart|try-restart|reload|force-reload|status}" >&2
        exit 3
    ;;
esac

exit $RETVAL
