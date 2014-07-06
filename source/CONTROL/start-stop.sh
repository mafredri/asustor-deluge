#!/bin/sh

APKG_PKG_DIR=/usr/local/AppCentral/deluge

DELUGED=$APKG_PKG_DIR/bin/deluged
DELUGE=$APKG_PKG_DIR/bin/deluge

DELUGED_USER="admin"
DELUGED_OPTS=""
DELUGEUI_START="true"
DELUGEUI_OPTS="-u web"

DELUGED_USER_HOME=$(getent passwd "${DELUGED_USER}" | cut -d ':' -f 6)
export HOME=$DELUGED_USER_HOME

# Change working directory as deluge will see this as the home directory
cd $HOME

start() {
	echo "Starting Deluged"
	start-stop-daemon --start --background --pidfile /var/run/deluged.pid --make-pidfile \
	--chuid "${DELUGED_USER}" --user "${DELUGED_USER}" \
	--exec $DELUGED -- --do-not-daemonize $DELUGED_OPTS


	if [ "${DELUGEUI_START}" = "true" ] ; then
		echo "Starting Deluge"
		start-stop-daemon --start --background --pidfile /var/run/deluge.pid --make-pidfile \
		--exec $DELUGE --chuid "${DELUGED_USER}" --user "${DELUGED_USER}" -- $DELUGEUI_OPTS
	fi
}

stop() {
	echo "Stopping Deluged"
	start-stop-daemon --stop --user "${DELUGED_USER}" \
	--name deluged --pidfile /var/run/deluged.pid


	if [ "${DELUGEUI_START}" = "true" ] ; then
		echo "Stopping Deluge"
		start-stop-daemon --stop --user "${DELUGED_USER}" \
		--name deluge --pidfile /var/run/deluge.pid
	fi
}

case $1 in
	start)
		start
		;;

	stop)
		stop
		;;
	restart)
		stop
		start
		;;
	*)
		echo "usage: $0 {start|stop|restart}"
		exit 1
		;;
esac

exit 0
