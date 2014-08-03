#!/bin/sh

DELUGED_USER="admin:administrators"
DELUGED_USER_HOME=$(getent passwd "${DELUGED_USER%:*}" | cut -d ':' -f 6)
DELUGED_CONF=${DELUGED_USER_HOME}/.config/deluge
