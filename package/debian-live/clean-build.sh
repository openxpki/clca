#!/bin/bash

# clear locks
echo "Clearing locks on chroot, killing processes"
fuser -f chroot
 
# run clean
echo "Running lb clean"
lb clean


# remove extra files
echo "Remove config"
rm -rf ./config
rm -vi sysconf.txt
rm -vi build.log

echo "Clean complete"

