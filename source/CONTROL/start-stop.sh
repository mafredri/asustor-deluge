#!/bin/sh

NAME="Deluge"
PACKAGE="deluge"

if [ -z "${APKG_PKG_DIR}" ]; then
	PKG_DIR=/usr/local/AppCentral/${PACKAGE}
else
	PKG_DIR=$APKG_PKG_DIR
fi

. "${PKG_DIR}/CONTROL/env.sh"

export PATH=${PKG_DIR}/bin:$PATH
export LD_LIBRARY_PATH=${PKG_DIR}/lib:${LD_LIBRARY_PATH}
export HOME=${DELUGED_USER_HOME}

DELUGED_LOGLEVEL=info
DELUGE_WEB_LOGLEVEL=info

DELUGED="${PKG_DIR}/bin/deluged"
DELUGED_LOG="${DELUGED_CONF}/deluged.log"
DELUGED_PID="${DELUGED_CONF}/deluged.pid"
DELUGE_WEB="${PKG_DIR}/bin/deluge-web"
DELUGE_WEB_PID="${DELUGED_CONF}/deluge-web.pid"
DELUGE_WEB_LOG="${DELUGED_CONF}/deluge-web.log"

USER=${DELUGED_USER%:*}
CHUID=${DELUGED_USER}

start_daemon() {
    # Set umask to create files with world r/w
    umask 0

	start-stop-daemon -S --quiet --pidfile "${DELUGED_PID}" --chuid "${CHUID}" \
		--user "${USER}" --exec "${DELUGED}" -- \
		--quiet --pidfile "${DELUGED_PID}" --config "${DELUGED_CONF}" \
		--logfile "${DELUGED_LOG}" --loglevel "${DELUGED_LOGLEVEL}"

	start-stop-daemon -S --quiet --background --pidfile "${DELUGE_WEB_PID}" \
		--make-pidfile --chuid "${CHUID}" --user "${USER}" \
		--exec "${DELUGE_WEB}" -- \
		--quiet --config "${DELUGED_CONF}" --logfile "${DELUGE_WEB_LOG}" \
		--loglevel "${DELUGE_WEB_LOGLEVEL}"
}

stop_daemon() {
	start-stop-daemon -K --quiet --user "${USER}" --pidfile "${DELUGED_PID}"
	start-stop-daemon -K --quiet --user "${USER}" --pidfile "${DELUGE_WEB_PID}"

	wait_for_status 1 20

	if [ $? -eq 1 ]; then
		echo "Taking too long, killing service..."
		start-stop-daemon -K --signal 9 --quiet --user "${USER}" --pidfile "${DELUGED_PID}"
		start-stop-daemon -K --signal 9 --quiet --user "${USER}" --pidfile "${DELUGE_WEB_PID}"
	fi
}

daemon_status() {
	start-stop-daemon -K --quiet --test --user "${USER}" --pidfile "${DELUGED_PID}"
	ret1=$?
	start-stop-daemon -K --quiet --test  --user "${USER}" --pidfile "${DELUGE_WEB_PID}"
	ret2=$?

    if [ $ret1 -eq 0 ] || [ $ret2 -eq 0 ]; then
    	return 0
    fi

    return 1
}

wait_for_status() {
    counter=$2
    while [ "${counter}" -gt 0 ]; do
        if ! daemon_status; then
        	return 0
        fi
        counter=$(( counter - 1 ))
        sleep 1
    done
    return 1
}

case $1 in
	start)
		if ! daemon_status; then
            echo "Starting ${NAME}..."
            start_daemon
        else
            echo "${NAME} is already running"
        fi
		;;

	stop)
		if daemon_status; then
            echo "Stopping ${NAME}..."
            stop_daemon
        else
            echo "${NAME} is not running"
        fi
		;;
	restart)
		if daemon_status; then
			echo "Stopping ${NAME}..."
			stop_daemon
		fi
		echo "Starting ${NAME}..."
		start_daemon
		;;
	status)
		if daemon_status; then
		    echo "${NAME} is running"
		    exit 0
		else
		    echo "${NAME} is not running"
		    exit 1
		fi
		;;
	*)
		echo "usage: $0 {start|stop|restart|status}"
		exit 1
		;;
esac

exit 0
