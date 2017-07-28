#!/bin/sh

if [ -z $APKG_PKG_DIR ]; then
	PKG_DIR=/usr/local/AppCentral/deluge
else
	PKG_DIR=$APKG_PKG_DIR
fi

# Source env variables
. ${PKG_DIR}/CONTROL/env.sh

rm -rf ${DELUGED_CONF}

exit 0
