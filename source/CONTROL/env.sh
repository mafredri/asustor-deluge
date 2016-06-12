#!/bin/sh

DELUGED_USER="admin:administrators"
DELUGED_USER_HOME=$(getent passwd "${DELUGED_USER%:*}" | cut -d ':' -f 6)
DELUGED_CONF=${DELUGED_USER_HOME}/.config/deluge

export DELUGED_USER DELUGED_USER_HOME DELUGED_CONF

HOME=${DELUGED_USER_HOME}

PATH=${PKG_DIR}/bin:$PATH
PATH=${PKG_DIR}/usr/bin:$PATH
PATH=${PKG_DIR}/usr/lib/p7zip:$PATH

export HOME PATH
