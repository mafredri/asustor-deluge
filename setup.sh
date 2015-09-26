#!/bin/bash

sudo echo -n

BUMP_VERSION=0
FETCH_PACKAGES=0
GEOIP_OPTS=""

show_help() {
    echo "Options:
  -f    Fetch packages instead of using local ones
  -g    Force GeoIP database update
  -b    Bump version
  -h    This help"
    exit 0
}

while getopts :fgbh opts; do
   case $opts in
        f)
            FETCH_PACKAGES=1
            ;;
        g)
            GEOIP_OPTS="--force"
            ;;
        b)
            BUMP_VERSION=1
            ;;
        h)
            show_help
            ;;
   esac
done

VERSION=$(<version.txt)
if [ "$BUMP_VERSION" -eq 1 ]; then
    echo "Bumping version..."
    version_begin=${VERSION%.*}
    version_part=${VERSION##*.}
    if [ "$version_part" = "$VERSION" ]; then
        version_part=0
    else
        version_part=$((version_part + 1))
    fi
    VERSION="${version_begin}.${version_part}"
    echo "$VERSION" > version.txt
    echo "New version $VERSION"
fi

ROOT=$(cd "$(dirname "${0}")" && pwd)
PACKAGE=$(basename "${ROOT}")

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
scripts/geoipupdate.sh $GEOIP_OPTS

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
        rsync -ram --delete --include-from=packages.txt --exclude="*/*" --exclude="Packages" $HOST:$cross/packages/* $PKG_DIR
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

    echo "Copying apkg skeleton..."
    cp -af source/* $WORK_DIR

    echo "Unpacking files..."
    TMP_DIR=$(mktemp -d /tmp/$PACKAGE.XXXXXX)
    (cd $TMP_DIR; for pkg in $ROOT/$PKG_DIR/*/*.tbz2; do tar xjf $pkg; done)

    echo "Grabbing required files..."
    mv $TMP_DIR/usr/bin/unrar $WORK_DIR/bin
    mv $TMP_DIR/usr/lib*/p7zip/* $WORK_DIR/bin
    mv $TMP_DIR/usr/bin/p7zip $WORK_DIR/bin
    mv $TMP_DIR/usr/lib*/libboost_system* $WORK_DIR/lib
    mv $TMP_DIR/usr/lib*/libboost_python-2.7* $WORK_DIR/lib
    mv $TMP_DIR/usr/lib*/libtorrent-rasterbar* $WORK_DIR/lib
    mv $TMP_DIR/usr/lib*/libGeoIP* $WORK_DIR/lib
    mv $TMP_DIR/usr/lib*/libunrar* $WORK_DIR/lib
    # mv $TMP_DIR/usr/lib*/p7zip $WORK_DIR/lib
    mv $TMP_DIR/usr/lib*/python2.7/site-packages/* $WORK_DIR/lib/python2.7/site-packages
    # Temporary until ASUSTOR includes these in the Python app
    # mv $TMP_DIR/usr/lib*/libpython2.7.so* $WORK_DIR/lib

    rm -rf $TMP_DIR

    echo "Finalizing..."
    echo "Setting version to ${VERSION}"
    sed -i '' -e "s^ADM_ARCH^${arch}^" -e "s^APKG_VERSION^${VERSION}^" $WORK_DIR/CONTROL/config.json

    echo "Building APK..."
    # APKs require root privileges, make sure priviliges are correct
    sudo chown -R 0:0 $WORK_DIR
    sudo scripts/apkg-tools.py create $WORK_DIR --destination dist/
    sudo chown -R $(whoami) dist

    # Reset permissions on working directory
    sudo chown -R $(whoami) $WORK_DIR

    echo "Done!"
done
