#!/usr/bin/env zsh

emulate -L zsh

script_dir=${${(%):-%x}:A:h}
setup_yaml=$script_dir/setup.yml

source ./scripts/setup/general-setup.sh
source ./scripts/setup/parse-setup-yaml.sh
source ./scripts/setup/python-site-packages.sh

cd -q $script_dir

# Update GeoIP databse
./scripts/geoipupdate.sh --force

ssh_host=$setup_ssh
build_apk='build/apk'
build_files='build/files'

mkdir -p $build_files
mkdir -p dist

build_arch() {
	local arch=$1
	local prefix=$2
	log() {
		printf "%8s: $@\n" $arch
	}

	log "Building $setup_name $setup_version for $arch"

	# Cleanup build directory
	[[ -d $build_apk/$arch ]] && rm -rf $build_apk/$arch
	mkdir -p $build_apk/$arch

	log "Copying APK skeleton"
	rsync -a source/ $build_apk/$arch

	site_package_files=( $(get_site_packages $ssh_host $prefix "$setup_site_packages") )
	files=(
		$prefix$^setup_files
		$prefix$^site_package_files
	)

	write_pkgversions $ssh_host $prefix "$files" pkgversions/$arch.txt &

	log "Updating runpath on remote..."
	patched_files=$(update_runpath $ssh_host $prefix /usr/local/AppCentral/$setup_package/lib "$files")
	log "Patched runpath for: $patched_files"

	log "Rsyncing files..."
	rsync -q -a --relative --delete --exclude '*.py[cdo]' \
		$ssh_host:"$files" $build_files/

	if (( $? )); then
		log "Failed fetching files for $arch"
		continue
	fi

	log "Copying $arch files to $build_apk/$arch..."
	rsync -a $build_files$prefix/ $build_apk/$arch/

	log "Remove .DS_Store"
	find $build_apk/$arch -name .DS_Store -exec rm {} \;

	log "Removing usr from path"
	(cd $build_apk/$arch && mv usr/* ./ && rmdir usr)

	config2json $arch > $build_apk/$arch/CONTROL/config.json
	cp CHANGELOG.md $build_apk/$arch/CONTROL/changelog.txt

	log "Building APK..."
	build_apk $build_apk/$arch dist

	log "Done!"

	wait
}

for arch prefix in ${(kv)adm_arch}; do
	build_arch $arch $prefix &
done

wait

print "\nThank you, come again!"
