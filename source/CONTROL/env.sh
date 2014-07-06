#!/bin/sh

DELUGE_PATH=/usr/local/AppCentral/deluge

DELUGED_USER="admin"
DELUGED_OPTS=""
DELUGED_USER_HOME=$(getent passwd "${DELUGED_USER}" | cut -d ':' -f 6)
DELUGED_CONF=$DELUGED_USER_HOME/.config/deluge
DELUGEUI_START="true"
DELUGEUI_OPTS="-u web"

export PATH=$DELUGE_PATH/bin:$PATH
export LD_LIBRARY_PATH=$DELUGE_PATH/lib64:$DELUGE_PATH/lib:$LD_LIBRARY_PATH
export HOME=$DELUGED_USER_HOME
