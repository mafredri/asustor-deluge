#!/bin/sh

setup() {
    # Store the lib directory elsewhere while creating virtualenv, since
    # virtualenv will overwrite site-packages.
    mv $APKG_PKG_DIR/lib $APKG_TEMP_DIR/
    cd $APKG_PKG_DIR
    /usr/local/bin/virtualenv .
    rsync -ra $APKG_TEMP_DIR/lib $APKG_PKG_DIR/
}

case "$APKG_PKG_STATUS" in
	install)
        setup

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
        setup
		;;
	*)
		;;
esac

exit 0
