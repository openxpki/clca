mkdir -p $TARGETROOT/etc/rc.local.d

cat <<EOF >$TARGETROOT/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#

if [ -d /etc/rc.local.d ] ; then
    for FILE in /etc/rc.local.d/* ; do
        if [ -x \$FILE ] ; then
            \$FILE
        fi
    done
fi
exit 0
EOF
