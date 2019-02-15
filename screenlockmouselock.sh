#!/bin/bash
#Get working directory. It is directory where this script is located
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
# Is a useful one-liner which will give you the full directory name
# of the script no matter where it is being called from
# Use this if you aren't using the CONFIG_DIR
WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR=$HOME/.screenlockmouselock
DAEMON_PID=$CONFIG_DIR/daemon_pid
MONITOR_PID=$CONFIG_DIR/monitor_pid
FIFO=$CONFIG_DIR/lock_unlock_fifo
SCRIPTNAME=$0

XINPUT_PROP_ID=11 #update this to your mouse's ID

do_if_unlocked(){
	xinput set-prop $XINPUT_PROP_ID "Device Enabled" 1
}

do_if_locked(){
	xinput set-prop $XINPUT_PROP_ID "Device Enabled" 0
}

run_monitor(){
	gdbus monitor -e -d com.canonical.Unity -o /com/canonical/Unity/Session > "$FIFO"
}

run_daemon(){
	while true; do
		read -r line < "$FIFO"
		if grep LockRequested <<< "$line" > /dev/null; then
			do_if_locked
		fi
		if grep UnlockRequested <<< "$line" > /dev/null; then
			do_if_unlocked
		fi
	done
}

check_if_daemon_alive(){
	local PID=$1
	if [ ! -z "$PID" ]; then 
		if ps -p "$PID" > /dev/null; then
			return 0
		else
			echo "Pid file is not empty, but process is died."
			return 1
		fi
	else
		return 1
	fi
}

do_start() {
	PID=`cat "$DAEMON_PID"`
	if check_if_daemon_alive "$PID"; then
		echo "daemon is already running"
	else
		run_monitor &
		echo $! > "$MONITOR_PID"
		echo "Monitor started"

		run_daemon &
		echo $! > "$DAEMON_PID"
		echo "Daemon started"
	fi
}

do_stop() {
	local PID=`cat "$MONITOR_PID"`
	if check_if_daemon_alive "$PID"; then
		kill -15 "$PID"
		>"$MONITOR_PID"
		echo "Monitoring stopped"
	fi
	local PID=`cat "$DAEMON_PID"`
	if check_if_daemon_alive "$PID"; then
		kill -15 "$PID"
		>"$DAEMON_PID"
		echo "Daemon stopped"
	fi
}

# create $PIDS file if it is not exists in current dir yet
if [ ! -f "$MONITOR_PID" ]; then
	touch "$MONITOR_PID"
fi
# create $PIDS file if it is not exists in current dir yet
if [ ! -f "$DAEMON_PID" ]; then
	touch "$DAEMON_PID"
fi
# create $FIFO file if it is not exists in current dir yet
if [ ! -p "$FIFO" ]; then
	mkfifo "$FIFO"
fi

case "$1" in
	start)
		do_start
		;;
	stop)
		do_stop
		;;
	status)
		PID=`cat "$DAEMON_PID"`
		if check_if_daemon_alive $PID; then
			echo "Daemon is running. Pid is $PID"
		else
			echo "Daemon is not runnning"
		fi
		;;
	*)
		echo "Usage: $SCRIPTNAME {start|stop|status}" >&2
		exit 3
		;;
esac
