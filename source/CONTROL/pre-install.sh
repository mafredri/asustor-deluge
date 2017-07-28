#!/bin/sh

if [ -z $APKG_PKG_DIR ]; then
	PKG_DIR=/usr/local/AppCentral/deluge
else
	PKG_DIR=$APKG_PKG_DIR
fi

case "${APKG_PKG_STATUS}" in
	install)
		;;
	upgrade)
		# Source env variables
		. ${PKG_DIR}/CONTROL/env.sh

		# Back up Deluge configuration
		if [ -d ${DELUGED_CONF} ]; then
			mkdir ${APKG_TEMP_DIR}/config
			cp -af ${DELUGED_CONF}/* ${APKG_TEMP_DIR}/config/
		fi
		;;
	*)
		;;
esac

exit 0
