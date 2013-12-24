# additional packages for this addon
PACKAGES="$PACKAGES openssl opensc libccid"

# files to install
install -D -m 755 $BASE/bin/clca $TARGETROOT/usr/local/bin/clca
install -D -m 644 $BASE/etc/clca.cfg $TARGETROOT/usr/local/etc/clca.cfg
install -D -m 644 $BASE/etc/openssl.cnf $TARGETROOT/usr/local/etc/openssl.cnf
