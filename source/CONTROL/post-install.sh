#!/bin/sh

if [ -z $APKG_PKG_DIR ]; then
    PKG_DIR=/usr/local/AppCentral/deluge
else
    PKG_DIR=$APKG_PKG_DIR
fi

setup_virtualenv() {
    (cd ${PKG_DIR};
        mv lib/python2.7/site-packages ./
        virtualenv .
        mv site-packages/* lib/python2.7/site-packages && rmdir site-packages
        source bin/activate
        # Install deluge executables in the virtualenv
        easy_install deluge)
}

case "${APKG_PKG_STATUS}" in
	install)
        setup_virtualenv

        # Source env variables
        source ${PKG_DIR}/CONTROL/env.sh

        # If previous configurations don't exist, copy the initial template
        if [ ! -d ${DELUGED_CONF} ]; then
            mkdir -p ${DELUGED_CONF}
            cp ${PKG_DIR}/config/* ${DELUGED_CONF}/
            chown -R ${DELUGED_USER} ${DELUGED_CONF}
        fi
		;;
	upgrade)
        setup_virtualenv
		;;
	*)
		;;
esac

exit 0
