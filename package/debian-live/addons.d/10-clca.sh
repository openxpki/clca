# additional packages for this addon
PACKAGES="$PACKAGES openssl"

# files to install
install -D -m 755 $BASE/bin/clca $TARGET_ROOT/usr/local/bin/clca
install -D -m 644 $BASE/etc/clca.cfg $TARGET_ROOT/usr/local/etc/clca.cfg
install -D -m 644 $BASE/etc/openssl.cnf $TARGET_ROOT/usr/local/etc/openssl.cnf
