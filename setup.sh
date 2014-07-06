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

# We are only interested in files from these directories
KEEP_FILES="
usr/bin
usr/lib*
"

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

    # Create temp directory and copy the APKG template
    PKG_DIR=$(mktemp -d /tmp/${PACKAGE}_PACKAGES.XXXXXX)
    echo "Rsyncing packages..."
    rsync -ra --include-from=packages.txt --exclude="*/*" $HOST:$cross/packages/* $PKG_DIR

    TMP_DIR=$(mktemp -d /tmp/${PACKAGE}.XXXXXX)
    chmod 0755 $TMP_DIR

    echo "Unpacking files..."
    (cd $PKG_DIR; for pkg in $PKG_DIR/*/*.tbz2; do tar xjf $pkg; done)

    echo "Copying required files..."
    for file in $KEEP_FILES; do
        cp -af $PKG_DIR/$file $TMP_DIR
    done

    echo "Cleaning up package tmp..."
    rm -rf $PKG_DIR

    echo "Copying apkg skeleton..."
    cp -rf source/* $TMP_DIR

    echo "Finalizing..."
    echo "Setting version to ${VERSION}"
    sed -i '' -e "s^ADM_ARCH^${arch}^" -e "s^APKG_VERSION^${VERSION}^" $TMP_DIR/CONTROL/config.json

    echo "Updating shebangs..."
    for exec in $TMP_DIR/bin/*; do
        grep "#\!/usr" $exec | grep "#\!/usr/local/AppCentral" > /dev/null
        if [ $? -eq 1 ]; then
            vim -es -c '1 s^#!/usr^#!/usr/local/AppCentral/deluge^' -c wq $exec
        fi
    done

    echo "Building APK..."
    # APKs require root privileges, make sure priviliges are correct
    sudo chown -R 0:0 $TMP_DIR
    sudo scripts/apkg-tools.py create $TMP_DIR --destination dist/
    sudo chown -R $(whoami) dist

    echo "Done!"

    echo "Cleaning up..."
    sudo rm -rf $TMP_DIR
done
