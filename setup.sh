#!/bin/bash

FETCH_PACKAGES=0

show_help() {
    echo "Options:
  -f    Fetch packages instead of using local ones
  -h    This help"
    exit 0
}

while getopts :fh opts; do
   case $opts in
        f)
            FETCH_PACKAGES=1
            ;;
        h)
            show_help
            ;;
   esac
done


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
    PKG_DIR=build/packages/$arch
    if [ ! -d $PKG_DIR ]; then
        mkdir -p $PKG_DIR
    fi
    if [ $FETCH_PACKAGES -eq 1 ]; then
        echo "Rsyncing packages..."
        rsync -ram --include-from=packages.txt --exclude="*/*" --exclude="Packages" $HOST:$cross/packages/* $PKG_DIR
        PKG_INSTALLED=$(cd $PKG_DIR; ls -1 */*.tbz2 | sort)
        echo -e "# This file is auto-generated.\n${PKG_INSTALLED//.tbz2/}" > pkgversions_$arch.txt
    else
        echo "Using cached packages..."
    fi

    WORK_DIR=build/$arch
    if [ ! -d $WORK_DIR ]; then
        mkdir -p $WORK_DIR
    fi
    echo "Cleaning out ${WORK_DIR}..."
    rm -rf $WORK_DIR
    mkdir $WORK_DIR
    chmod 0755 $WORK_DIR

    echo "Unpacking files..."
    TMP_DIR=$(mktemp -d /tmp/$PACKAGE.XXXXXX)
    (cd $TMP_DIR; for pkg in $ROOT/$PKG_DIR/*/*.tbz2; do tar xjf $pkg; done)

    echo "Copying required files..."
    for file in $KEEP_FILES; do
        mv $TMP_DIR/$file $WORK_DIR
    done

    rm -rf $TMP_DIR

    # Merge lib and lib64
    if [ -d $WORK_DIR/lib64 ]; then
        mv $WORK_DIR/lib64/* $WORK_DIR/lib/
        rmdir $WORK_DIR/lib64
        (cd $WORK_DIR; ln -sf lib lib64)
    fi

    echo "Copying apkg skeleton..."
    cp -rf source/* $WORK_DIR

    echo "Finalizing..."
    echo "Setting version to ${VERSION}"
    sed -i '' -e "s^ADM_ARCH^${arch}^" -e "s^APKG_VERSION^${VERSION}^" $WORK_DIR/CONTROL/config.json

    echo "Updating shebangs..."
    for exec in $WORK_DIR/bin/*; do
        grep "#\!/usr" $exec | grep "#\!/usr/local/AppCentral" > /dev/null
        if [ $? -eq 1 ]; then
            vim -es -c '1 s^#!/usr^#!/usr/local/AppCentral/deluge^' -c wq $exec
        fi
    done

    echo "Building APK..."
    # APKs require root privileges, make sure priviliges are correct
    sudo chown -R 0:0 $WORK_DIR
    sudo scripts/apkg-tools.py create $WORK_DIR --destination dist/
    sudo chown -R $(whoami) dist

    # Reset permissions on working directory
    sudo chown -R $(whoami) $WORK_DIR

    echo "Done!"
done
