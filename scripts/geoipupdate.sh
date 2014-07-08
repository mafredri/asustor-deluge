#!/bin/sh
#
# Script borrowed and modified from Gentoo portage dev-libs/geoip/files/geoipupdate-r4.sh
#

GEOIP_MIRROR="https://geolite.maxmind.com/download/geoip/database"
GEOIPDIR=source/GeoIP
TMPDIR=

# Available databases:
#     GeoIPv6
#     GeoLiteCity
#     GeoLiteCityv6-beta/GeoLiteCityv6
#     asnum/GeoIPASNum
#     asnum/GeoIPASNumv6
#
DATABASES="
    GeoLiteCountry/GeoIP
"

if [ "${1}" = -f ] || [ "${1}" = --force ]; then
        force=true
fi

if [ ! -d "${GEOIPDIR}" ]; then
    mkdir "${GEOIPDIR}"
fi

cd $GEOIPDIR
if [ -n "${DATABASES}" ]; then
    TMPDIR=$(mktemp -d geoipupdate.XXXXXXXXXX)

    echo "Updating GeoIP databases..."

    for db in $DATABASES; do
        fname=$(basename $db)

        if [ ! -f "${fname}.dat" ] || [ ${force} ]; then
            wget --no-verbose -t 3 -T 60 \
                "${GEOIP_MIRROR}/${db}.dat.gz" \
                -O "${TMPDIR}/${fname}.dat.gz"
            if [ $? -eq 0 ]; then
                gunzip -fdc "${TMPDIR}/${fname}.dat.gz" > "${TMPDIR}/${fname}.dat"
                mv "${TMPDIR}/${fname}.dat" "${fname}.dat"
                chmod 0644 "${fname}.dat"
            fi
        fi
    done
    [ -d "${TMPDIR}" ] && rm -rf $TMPDIR
fi
