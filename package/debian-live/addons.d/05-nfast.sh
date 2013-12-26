NFAST_DISTFILE=`echo nCSS-linux-user-*.zip`

if [ -r "$NFAST_DISTFILE" ] ; then
    echo "nCipher driver package $NFAST_DISTFILE found, including in build process"
    USERNAME=nfast

	mkdir -p config/preseed
    echo "Include nfast group in list for default user..."
    echo "debconf passwd/user-default-groups string audio cdrom dialout floppy video plugdev netdev powerdev nfast" > config/preseed/add-nfast-group

    echo "Unpacking nFast drivers"
    TMPDIR=`mktemp -d tmpXXXXXX`
    mkdir -p $TMPDIR
    ( cd $TMPDIR && unzip ../$NFAST_DISTFILE )

    echo "Copying nCipher drivers and utilities to chroot config..."

    mkdir -p $TARGETROOT/usr/bin

    for nfast_pkg in hwsp hwcrhk ctls ; do
        TARBALL=`find $TMPDIR/ -type f -path "*/$nfast_pkg/*.tar"`
        if [ -r "$TARBALL" ] ; then
            echo "Installing $nfast_pkg"
            tar xf $TARBALL -C $TARGETROOT/
        fi
    done

    # copy documentation
    echo "Copying documentation"
    mkdir -p $TARGETROOT/opt/nfast/doc/
    #find nfast/ -path "*/document/*.pdf" -exec cp {} $TARGETROOT/opt/nfast/doc/ \;
	cp $TMPDIR/nCSS-linux/document/*.pdf $TARGETROOT/opt/nfast/doc/
    rm -rf $TMPDIR/

    # additional packages for this addon
    PACKAGES="$PACKAGES pciutils gcc"

    mkdir -p $TARGETROOT/etc/profile.d/
    cat <<EOF >$TARGETROOT/etc/profile.d/nfast-path
PATH="\$PATH:/opt/nfast/bin"; export PATH
EOF

    cat <<EOF >$TARGETROOT/etc/rc.local.d/nfast-compile
#!/bin/sh

LOG=/home/$USERNAME/nfast-inst.log

echo "Configuring nCipher module for building..." > \$LOG
(cd /opt/nfast/driver && ./configure) 2>&1 |tee -a \$LOG
echo "Building nCipher module..." |tee -a \$LOG
(cd /opt/nfast/driver && make) 2>&1 |tee -a \$LOG
echo "Installing nCipher module..." |tee -a \$LOG
/opt/nfast/sbin/install 2>&1 | tee -a \$LOG

echo "Modifying for persistence..." |tee -a \$LOG
(cd /opt/nfast/ && mv kmdata kmdata.orig && ln -s /home/$USERNAME/kmdata kmdata)

exit 0
EOF

    chmod 755 $TARGETROOT/etc/rc.local.d/nfast-compile

fi
