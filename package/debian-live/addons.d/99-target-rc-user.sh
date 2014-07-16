cat <<EOF >$TARGETROOT/etc/rc.local.d/rc-user
#!/bin/sh
# execute ~USER/.rc.local
#
# This script checks if the main user has a ".rc.local" file in his or
# her home directory and executes it if this is the case.
#

if [ -x /home/$USERNAME/.rc.local ] ; then
    /home/$USERNAME/.rc.local
fi
exit 0
EOF

chmod +x $TARGETROOT/etc/rc.local.d/rc-user
