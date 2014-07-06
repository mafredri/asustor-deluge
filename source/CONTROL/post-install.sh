#!/bin/sh

case "$APKG_PKG_STATUS" in
	install)
        # If previous configurations don't exist, copy the initial template
        DELUGED_USER="admin"
        DELUGED_USER_HOME=$(getent passwd "${DELUGED_USER}" | cut -d ':' -f 6)
        DELUGED_CONF=$DELUGED_USER_HOME/.config/deluge

        if [ ! -d $DELUGED_CONF ]; then
            mkdir -p $DELUGED_CONF
            cp $APKG_PKG_DIR/config/* $DELUGED_CONF/
            chown -R admin:administrators $DELUGED_CONF
        fi
		;;
	upgrade)
        #setup
		;;
	*)
		;;
esac

exit 0
