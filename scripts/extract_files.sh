#!/bin/bash
#
# This script copies the required files and libs required for Deluge
#
# Requirements: twisted pyopenssl pyxdg chardet setproctitle mako service_identity

if [[ "${PREFIX}" == "" ]]; then
    echo "The PREFIX variable must be set!"
    exit 1
fi

FILES="
${PREFIX}/usr/lib/libboost_python-2.7*.so*
${PREFIX}/usr/lib/libboost_system*.so*
${PREFIX}/usr/lib/libpython2.7.so*
${PREFIX}/usr/lib/libtorrent-rasterbar.so*
${PREFIX}/usr/lib/libssl.so*
${PREFIX}/usr/lib/libcrypto.so*
${PREFIX}/usr/bin/deluge*
"
SITE_PACKAGES=${PREFIX}/usr/lib/python2.7/site-packages
LOCAL_SITE_PACKAGES="${SITE_PACKAGES#${PREFIX}/usr/}"
PYTHON_PACKAGES="
openssl
cffi
characteristic
chardet
cryptography
deluge
libtorrent
mako
markupsafe
pyasn1
pyasn1_modules
pycparser
service_identity
setproctitle
six.py
twisted
xdg
zope
"
#setuptools
#
TMP_DIR=$(mktemp -d /tmp/deluge.XXXXXX)
echo $TMP_DIR

cd $TMP_DIR

for file in $FILES; do
    dirname=$(dirname $file)
    dirname="${dirname#${PREFIX}/usr/}"
    if [[ ! -d $dirname ]]; then
        mkdir -p $dirname
    fi
    cp -af $file $dirname/
done

# Create site-packages directory
mkdir -p $LOCAL_SITE_PACKAGES

# Copy all python modules
for package in $PYTHON_PACKAGES; do
    find $SITE_PACKAGES -maxdepth 1 -iname "*${package}*" -exec cp -af {} $LOCAL_SITE_PACKAGES/ \;
done

# Clean up compiled python files
find $LOCAL_SITE_PACKAGES -name "*.py[cdo]" -exec rm {} \;
