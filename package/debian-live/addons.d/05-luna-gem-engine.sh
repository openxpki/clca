LUNA_DIR=luna
LUNA_OPENSSL_TOOLKIT=$LUNA_DIR/*OPENSSL_TOOLKIT_LunaSA_*.tar*

if [ -e $LUNA_OPENSSL_TOOLKIT ] ; then
    echo "Gemalto SafeNet Luna OpenSSL Engine found, including in build process"

    # additional packages for this addon
    PACKAGES="$PACKAGES pciutils build-essential libssl-dev"

    if [ -n "$ARCHITECTURE" ] ; then
        ARCH=$ARCHITECTURE
    else
        ARCH=`uname -m`
    fi

    case $ARCH in
        amd64|x86_64)
            PACKAGES="$PACKAGES linux-headers-amd64"
            WORDSIZE=64
            ;;
        *)
            echo "ERROR: unsupported architecture $ARCH. Please handle this case in the luna addons file"
            exit 1
            ;;
    esac

    echo "Unpacking Luna SA HSM drivers"
    mkdir -p $TARGETROOT/usr/src/
    cat $LUNA_OPENSSL_TOOLKIT | ( cd $TARGETROOT/usr/src ; tar xf - )

    echo "Copying Luna drivers and utilities to chroot config..."

    cat <<EOF >$TARGETROOT/etc/rc.local.d/luna-compile
#!/bin/sh

LOG=/home/$USERNAME/luna-inst.log

echo "Installing Luna gem engine..." > \$LOG
cd /usr/src/gemengine*
OPENSSL_VERSION=\`openssl version | awk '{ print \$2 }' | tr -cd '0-9.'\`
OPENSSL_ENGINE_DIR=\`./gembuild locate-engines | grep ^/\`

cp builds/linux/debian/$WORDSIZE/\$OPENSSL_VERSION/sautil /usr/local/bin/
cp builds/linux/debian/$WORDSIZE/\$OPENSSL_VERSION/*.so \$OPENSSL_ENGINE_DIR/

exit 0
EOF

    chmod 755 $TARGETROOT/etc/rc.local.d/luna-compile

fi
