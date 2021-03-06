#!/bin/bash

# note its necessary to login at least once in docker. it will save the config to the user
if [ "$1" == "" ];
then
	echo "$0 <docker-user>"
	exit 1
fi

DOCKER_USER=$1 

BASEDIR="images"
for version in 13.1 13.2 tumbleweed
do
	ROOT_DIR=$(realpath $BASEDIR/$version)
	if [ -d  $ROOT_DIR ]; then
		rm -rf $ROOT_DIR
	else
		mkdir -p $ROOT_DIR
	fi

	if [ $version == "tumbleweed" ]; then
		zypper -R $ROOT_DIR  ar http://download.opensuse.org/$version/repo/oss/ repo-oss
	else
		zypper -R $ROOT_DIR  ar http://download.opensuse.org/distribution/$version/repo/oss/ repo-oss
	fi
	zypper -R $ROOT_DIR  ar http://download.opensuse.org/update/$version/ repo-update
	zypper --gpg-auto-import-keys  -R $ROOT_DIR ref
	zypper -n  -R $ROOT_DIR in zypper

	# packages to be removed
	for pkg in  postfix udev dracut  dbus-1 rsyslog wicked-service wicked fipscheck sysvinit-tools cron cronie systemd-bash-completion systemd-sysvinit libusb python3 kmod-compat bash-doc xz suse-module-tools perl-base-5 python3-setuptools python3-base aaa_base udev-mini perl-Bootloader
	do
		# remove it
		rpm --root $ROOT_DIR -e --nodeps $pkg 2>/dev/null
	done

	tar -C $ROOT_DIR -c . | docker import - $DOCKER_USER/opensuse_${version}:latest
	echo $DOCKER_USER | docker login  # we must interact with it
	docker push $DOCKER_USER/opensuse_${version}
	docker rmi -f $DOCKER_USER/opensuse_${version}
	sleep 3
	umount  $ROOT_DIR/sys 2>/dev/null
	rm -rf $ROOT_DIR
done
