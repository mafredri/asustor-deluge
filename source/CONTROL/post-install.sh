#!/bin/sh

APKG_PKG_DIR=/usr/local/AppCentral/deluge

case "$APKG_PKG_STATUS" in
	install)
        source $APKG_PKG_DIR/CONTROL/env.sh

        # If previous configurations don't exist, copy the initial template
        if [ ! -d $DELUGED_CONF ]; then
            mkdir -p $DELUGED_CONF
            cp $APKG_PKG_DIR/config/* $DELUGED_CONF/
            chown -R admin:administrators $DELUGED_CONF
        fi
		;;
	upgrade)
		;;
	*)
		;;
esac

exit 0
