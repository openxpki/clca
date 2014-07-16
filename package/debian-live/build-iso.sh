#!/bin/bash
# 
# build-iso.sh - builds OpenXPKI Project Root CA Bootable Live Medium
# Copyright (c) 2013 OpenXPKI Project
# Authors: Scott Hardin, Gideon Knocke and Martin Bartosch
#

ORGANIZATION="OpenXPKI"
USERNAME="user"
HOSTNAME="rootca"
#ARCHITECTURE="i386"
#ARCHITECTURE="amd64"
#LINUX_FLAVOUR="686-pae"
PACKAGES=""

#DRYRUN=1

DISTRIBUTION=`lsb_release -c | awk '{ print $2 }'`
if [ $? != 0 ] ; then
    echo "ERROR: could not run lsb_release"
    exit 1
fi

case $DISTRIBUTION in
    wheezy)
        echo "Building for Debian Wheezy"
        APPEND_OPTIONS="$APPEND_OPTIONS boot=live config persistence silent username=\$USERNAME hostname=\$HOSTNAME"
	TARGETROOT=config/includes.chroot
        ;;
    *)
        echo "ERROR: unsupported distribution $DISTRIBUTION"
        exit 1
        ;;
esac


# use the same keyboard layout as on build system
if [ -r /etc/default/keyboard ] ; then
    . /etc/default/keyboard
    echo "Using keyboard layouts $XKBLAYOUT from build system"
    KEYBOARD_LAYOUTS=$XKBLAYOUT
fi

# remove existing conf
if [ -d config/ ]; then
    echo "Cleaning up configuration..."
    rm -rf config sysconf.txt
fi

echo "Cleaning up previous builds..."
lb clean

# the following variables can be used by addons
BASE=../..
[ -z "$TARGETROOT" ] && exit 1
mkdir -p $TARGETROOT

# base packages
PACKAGES="make vim less pandoc dosfstools python"

echo "Installing addons..."
if [ -d "addons.d" ]; then
   for i in addons.d/*.sh; do
      if [ -r $i ]; then
         echo "* Addon: $i"
         . $i
      fi
   done
fi

LB_OPTIONS="--iso-application $ORGANIZATION-Live-RootCA \
--iso-publisher OpenXPKI \
--iso-volume $ORGANIZATION-Live-RootCA \
--distribution $DISTRIBUTION"

[ -n "$ARCHITECTURE" ] && LB_OPTIONS="$LB_OPTIONS --architectures \"$ARCHITECTURE\""
[ -n "$LINUX_FLAVOUR" ] && LB_OPTIONS="$LB_OPTIONS --linux-flavours \"$LINUX_FLAVOUR\""
[ -n "$KEYBOARD_LAYOUTS" ] && APPEND_OPTIONS="$APPEND_OPTIONS keyboard-layouts=$KEYBOARD_LAYOUTS"

echo "Generating initial configuration..."
APPEND_OPTIONS="`eval echo $APPEND_OPTIONS`"
echo "bootappend options: $APPEND_OPTIONS"

lb config $LB_OPTIONS --bootappend-live "$APPEND_OPTIONS" | tee build.log
if [ $? != 0 ] ; then
	echo "ERROR: lb config failed"
	exit 1
fi

echo "Injecting additional packages:"
echo $PACKAGES
mkdir -p config/package-lists/
echo $PACKAGES > config/package-lists/my.list.chroot

echo "Creating overview of systemconfiguration..."
if [ ! -f "sysconf.txt" ]; then
   lb config --dump > sysconf.txt; else
   echo "couldn't create file 'sysconf.txt'. Please remove 'sysconf.txt'"
fi

if [ -n "$DRYRUN" ] ; then
    echo "Dry run - exiting"
    exit 0
fi

echo "Building the ISO image (takes about 10 min with packages in cache)..."
lb build 2>&1 | tee -a build.log
if [ $? != 0 ] ; then
	echo "ERROR: lb build failed"
	exit 1
fi

echo "Build is complete. To clean up, run 'lb clean; rm -rf ./config'"

