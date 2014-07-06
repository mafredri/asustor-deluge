#!/bin/sh -e

APKG_PKG_DIR=/usr/local/AppCentral/deluge

source $APKG_PKG_DIR/CONTROL/env.sh

start() {
	echo "Starting Deluged"
	(cd $HOME;
		start-stop-daemon --start --background --pidfile /var/run/deluged.pid --make-pidfile \
		--chuid "${DELUGED_USER}" --user "${DELUGED_USER}" --exec $APKG_PKG_DIR/bin/deluged -- \
		--do-not-daemonize $DELUGED_OPTS)


	if [ "${DELUGEUI_START}" = "true" ] ; then
		echo "Starting Deluge"
		(cd $HOME;
			start-stop-daemon --start --background --pidfile /var/run/deluge.pid --make-pidfile \
			--exec $APKG_PKG_DIR/bin/deluge --chuid "${DELUGED_USER}" --user "${DELUGED_USER}" -- \
			$DELUGEUI_OPTS)
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
