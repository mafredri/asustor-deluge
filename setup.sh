#!/bin/bash

ROOT=$(cd $(dirname "${0}") && pwd)
PACKAGE=$(basename "${ROOT}")
VERSION=$(<version.txt)

# This defines the arches available and from where to fetch the files
# ARCH:PREFIX
ADM_ARCH=(
    "x86-64:/cross/x86_64-asustor-linux-gnu"
    "i386:/cross/i686-asustor-linux-gnu"
)

# Set hostname (ssh) from where to fetch the files
HOST=asustorx

cd $ROOT

if [[ ! -d dist ]]; then
    mkdir dist
fi

# Fetch GeoIP database
scripts/geoipupdate.sh

for arch in ${ADM_ARCH[@]}; do
    cross=${arch#*:}
    arch=${arch%:*}

    echo "Building ${arch} from ${HOST}:${cross}"

    # Run script on remote host which gathers all files in a temp-directory and echoes the path
    FILES=$(ssh $HOST PREFIX=${cross} 'bash -s' < scripts/extract_files.sh)
    if [[ $? -eq 1 ]]; then
        echo $FILES
        echo "Failed to extract files, skipping..."
        continue
    fi

    # Create temp directory and copy the APKG template
    TMP_DIR=$(mktemp -d /tmp/$PACKAGE.XXXXXX)
    chmod 0755 $TMP_DIR
    cp -rf source/* $TMP_DIR

    # Set the ARCH and VERSION
    sed -i '' -e "s^ADM_ARCH^${arch}^" -e "s^APKG_VERSION^${VERSION}^" $TMP_DIR/CONTROL/config.json

    # Copy files from the host machine
    rsync -ra $HOST:$FILES/* $TMP_DIR

    # Update Deluge scripts to use correct python
    sed -i '' -e 's^#!/usr/bin/python2.7^#!/usr/local/AppCentral/deluge/bin/python2.7^' $TMP_DIR/bin/*

    # APKs require root privileges, make sure priviliges are correct
    sudo chown -R 0:0 $TMP_DIR
    sudo scripts/apkg-tools.py create $TMP_DIR --destination dist/
    sudo chown -R $(whoami) dist

    echo "Done with building APK"

    echo "Cleaning up..."
    sudo rm -rf $TMP_DIR
done
