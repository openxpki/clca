LUNA_DIR=luna/

if [ -r "$LUNA_DIR/install.sh" ] ; then
    echo "Gemalto SafeNet Luna HSM drivers found, including in build process"

    # additional packages for this addon
    PACKAGES="$PACKAGES pciutils alien"

    if [ -n "$ARCHITECTURE" ] ; then
        ARCH=$ARCHITECTURE
    else
        ARCH=`uname -m`
    fi

    case $ARCH in
        amd64|x86_64)
            PACKAGES="$PACKAGES"
            ;;
        *)
            echo "ERROR: unsupported architecture $ARCH. Please handle this case in the luna addons file"
            exit 1
            ;;
    esac

    mkdir -p config/preseed

    echo "Copying Luna SA HSM software"
    mkdir -p $TARGETROOT/usr/safenet/SOFTWARE/
    cp $LUNA_DIR/*.rpm $TARGETROOT/usr/safenet/SOFTWARE/
    cp $LUNA_DIR/common $TARGETROOT/usr/safenet/SOFTWARE/
    cp $LUNA_DIR/*.sh $TARGETROOT/usr/safenet/SOFTWARE/

    cp $LUNA_DIR/install.sh $TARGETROOT/usr/safenet/SOFTWARE/install-batch.sh
    patch $TARGETROOT/usr/safenet/SOFTWARE/install-batch.sh < addons.d/install-batch.sh.patch

    chmod 755 $TARGETROOT/usr/safenet/SOFTWARE/*.sh

    mkdir -p $TARGETROOT/etc/profile.d/
    cat <<EOF >$TARGETROOT/etc/profile.d/luna-path.sh
PATH="\$PATH:/usr/safenet/lunaclient/bin"; export PATH
EOF

    cat <<EOF >$TARGETROOT/etc/rc.local.d/luna-packages
#!/bin/sh

LOG=/home/$USERNAME/luna-packages.log

cd /usr/safenet/SOFTWARE
./install-batch.sh

echo "Modifying for persistence..." |tee -a \$LOG

mkdir -p /home/$USERNAME/luna/cert/server
mkdir -p /home/$USERNAME/luna/cert/client
chown -R $USERNAME /home/$USERNAME/luna/

(cd /usr/safenet/lunaclient/ && mv cert cert.orig && ln -s /home/$USERNAME/luna/cert cert)

if [ ! -e /home/$USERNAME/luna/Chrystoki.conf ] ; then
    cp /etc/Chrystoki.conf /home/$USERNAME/luna/Chrystoki.conf
fi
(cd /etc/ && mv Chrystoki.conf Chrystoki.conf.orig && ln -s /home/$USERNAME/luna/Chrystoki.conf Chrystoki.conf)

exit 0
EOF

    chmod 755 $TARGETROOT/etc/rc.local.d/luna-packages

fi
