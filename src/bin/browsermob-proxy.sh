#!/bin/bash
#
# browsermob-proxy.sh
#	start | stop browsermob-proxy.sh

JAR=browsermob-proxy-2.0-beta-7-SNAPSHOT-standalone.jar
NAME=browsermob-proxy
PARAMS="-port 9090"

# special case - where is the JAR file?
DATA_DIR="@@DATA_DIR@@"
if [[ $DATA_DIR == "@""@DATA_DIR@@" ]] ; then
	# we are running out of a vendor folder
	DATA_DIR="`dirname $0`/../data/webdriver"
fi

function die() {
	echo "*** error: $@"
	exit 1
}

# make sure we have Java installed
if ! which java > /dev/null 2>&1 ; then
	die "java not found. please install and then try again"
fi

function start() {
	if ! is_running ; then
		# start the process
		echo "Starting $NAME in a screen"
		screen -d -m -S $NAME java -jar "$DATA_DIR/$JAR" $PARAMS

		# did it start?
		sleep 1
		is_running
	fi
}

function stop() {
	local pid=`get_pid`

	if [[ -z $pid ]] ; then
		echo "$NAME was not running"
		return 0
	fi

	kill $pid
	pid=`get_pid`
	if [[ -n $pid ]] ; then
		sleep 2
		pid=`get_pid`
	fi

	if [[ -n $pid ]] ; then
		kill -9 $pid
		pid=`get_pid`
	fi

	if [[ -n $pid ]] ; then
		echo "$NAME is running as pid $pid, and has ignored attempts to terminate"
		return 1
	fi

	echo "$NAME has been stopped"
}
function restart() {
	local pid=`get_pid`

	if [[ -n $pid ]] ; then
		stop
	fi

	start
}

function is_running() {
	local pid=`get_pid`

	if [[ -n $pid ]] ; then
		echo "$NAME is running as pid $pid"
		return 0
	fi

	echo "$NAME is not running"
	return 1
}

function monitor() {
	local pid=`get_pid`

	if [[ -z $pid ]] ; then
		echo "$NAME is not running"
		exit 1
	fi

	screen -rd $NAME
}

function usage() {
	echo "usage: $NAME.sh <start|stop|restart|status|monitor>"
}

function get_pid() {
	# get the pid of our daemon
	local pid=`ps -ef | grep "$NAME" | grep [S]CREEN | awk {' print $2 '}`

	if [[ -n $pid ]] ; then
		echo "$pid"
	fi
}

case "$1" in
	"status")
		is_running
		;;
	"stop")
		stop
		;;
	"restart")
		restart
		;;
	"start")
		start
		;;
	"monitor")
		monitor
		;;
	*)
		usage
		;;
esac