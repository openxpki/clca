NFAST_DISTFILE=`echo nCSS-linux-user-*.zip`

if [ -r "$NFAST_DISTFILE" ] ; then
    echo "nCipher driver package $NFAST_DISTFILE found, including in build process"
    USERNAME=nfast

    # additional packages for this addon
    PACKAGES="$PACKAGES pciutils build-essential module-assistant"

    if [ -n "$ARCHITECTURE" ] ; then
        ARCH=$ARCHITECTURE
    else
        ARCH=`uname -m`
    fi

    case $ARCH in
        amd64|x86_64)
            PACKAGES="$PACKAGES linux-headers-amd64"
            ;;
        *)
            echo "ERROR: unsupported architecture $ARCH. Please handle this case in the ncipher addons file"
            exit 1
            ;;
    esac

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
        TARBALLS=`find $TMPDIR/ -type f -path "*/$nfast_pkg/*.tar"`
        for file in $TARBALLS ; do
            if [ -r "$file" ] ; then
                echo "Installing $nfast_pkg ($file)"
                tar xf $file -C $TARGETROOT/
            fi
        done
    done

    # copy documentation
    echo "Copying documentation"
    mkdir -p $TARGETROOT/opt/nfast/doc/
    find $TMPDIR -type f  -name '*.pdf' -exec cp {} $TARGETROOT/opt/nfast/doc/ \;
    rm -rf $TMPDIR/

    mkdir -p $TARGETROOT/etc/profile.d/
    cat <<EOF >$TARGETROOT/etc/profile.d/nfast-path.sh
PATH="\$PATH:/opt/nfast/bin"; export PATH
EOF

    cat <<EOF >$TARGETROOT/etc/rc.local.d/nfast-compile
#!/bin/sh

LOG=/home/$USERNAME/nfast-inst.log

if [ -e /etc/init.d/nc_hardserver ] ; then
    echo "nCipher software already installed. Skipping." > \$LOG
    exit 0
fi

echo "Configuring nCipher module for building..." > \$LOG
(cd /opt/nfast/driver && ./configure) 2>&1 |tee -a \$LOG
echo "Building nCipher module..." |tee -a \$LOG
(cd /opt/nfast/driver && make && make install) 2>&1 |tee -a \$LOG
echo "Installing nCipher module..." |tee -a \$LOG
/opt/nfast/sbin/install 2>&1 | tee -a \$LOG

echo "Modifying for persistence..." |tee -a \$LOG
(cd /opt/nfast/ && mv kmdata kmdata.orig && ln -s /home/$USERNAME/kmdata kmdata)

exit 0
EOF

    chmod 755 $TARGETROOT/etc/rc.local.d/nfast-compile

fi
