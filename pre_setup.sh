#!/usr/bin/env zsh
#
# Script borrowed and modified from Gentoo portage dev-libs/geoip/files/geoipupdate-r4.sh
#

GEOIP_MIRROR="https://geolite.maxmind.com/download/geoip/database"
GEOIPDIR=source/GeoIP
TMPDIR=
DATABASES=(
	GeoLiteCountry/GeoIP
	# GeoIPv6
	# GeoLiteCity
	# GeoLiteCityv6-beta/GeoLiteCityv6
	# asnum/GeoIPASNum
	# asnum/GeoIPASNumv6
)

[[ -d $GEOIPDIR ]] || mkdir $GEOIPDIR

(cd $GEOIPDIR;
	if (( ${#DATABASES} )); then
		TMPDIR=$(mktemp -d geoipupdate.XXXXXXXXXX)

		echo "Updating GeoIP databases..."
		for db in $DATABASES; do
			fname=${db:t}

			if [[ -f ${fname}.dat ]] && [[ -z $(find . -name ${fname}.dat -mmin +1440) ]]; then
				echo "$db is less than a day old, skipping..."
				continue
			fi

			wget --no-verbose -t 3 -T 60 \
				"${GEOIP_MIRROR}/${db}.dat.gz" \
				-O "${TMPDIR}/${fname}.dat.gz"
			if [ $? -eq 0 ]; then
				gunzip -fdc "${TMPDIR}/${fname}.dat.gz" > "${TMPDIR}/${fname}.dat"
				mv "${TMPDIR}/${fname}.dat" "${fname}.dat"
				chmod 0644 "${fname}.dat"
			fi
		done
		[[ -d $TMPDIR ]] && rm -rf $TMPDIR
	fi
)
