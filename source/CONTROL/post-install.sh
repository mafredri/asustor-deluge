#!/bin/sh

if [ -z $APKG_PKG_DIR ]; then
	PKG_DIR=/usr/local/AppCentral/deluge
else
	PKG_DIR=$APKG_PKG_DIR
fi

# Source env variables
. ${PKG_DIR}/CONTROL/env.sh

setup_virtualenv() {
	(cd ${PKG_DIR};
		# Remove placeholders
		rm bin/deluged bin/deluge-web

		mv lib/python2.7/lib-dynload ./
		mv lib/python2.7/site-packages ./
		virtualenv .

		# Rebuild lib-dynload by replacing symlink with a directory and instead
		# link to each file from the system lib-dynload separately.
		# This allows us to make changed to lib-dynload without affecting the
		# system Python.
		lib_dynload=$(readlink -f lib/python2.7/lib-dynload)
		rm lib/python2.7/lib-dynload &&
		mkdir lib/python2.7/lib-dynload &&
		(cd lib/python2.7/lib-dynload;
			for i in "${lib_dynload}"/*; do
				ln -s $i ./
			done
		)
		mv lib-dynload/* lib/python2.7/lib-dynload && rmdir lib-dynload
		mv site-packages/* lib/python2.7/site-packages && rmdir site-packages

		. bin/activate
		# Install deluge executables in the virtualenv
		easy_install deluge
	)
}

case "${APKG_PKG_STATUS}" in
	install)
		setup_virtualenv

		# If previous configurations don't exist, copy the initial template
		if [ ! -d ${DELUGED_CONF} ]; then
			mkdir -p ${DELUGED_CONF}
			cp ${PKG_DIR}/config/* ${DELUGED_CONF}/
			chown -R ${DELUGED_USER} "${DELUGED_CONF}/../"
		fi
		;;
	upgrade)
		setup_virtualenv

		# Restore previous Deluge configuration if it exists
		if [ -d ${APKG_TEMP_DIR}/config ]; then
			if [ ! -d ${DELUGED_CONF} ]; then
				mkdir ${DELUGED_CONF}
			fi
			cp -af ${APKG_TEMP_DIR}/config/* ${DELUGED_CONF}/
		fi

		# Make sure the parent config directory has the correct permissions
		chown -R ${DELUGED_USER} "${DELUGED_CONF}/../"
		;;
	*)
		;;
esac

exit 0
