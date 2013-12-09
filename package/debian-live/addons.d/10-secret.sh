# additional packages for this addon
PACKAGES="$PACKAGES libclass-std-perl"

# files to install
install -D -m 755 $BASE/bin/secret $TARGET_ROOT/usr/local/bin/secret

for i in `( cd $BASE/lib && find . -type f )` ; do
    install -D -m 644 $BASE/lib/$i $TARGET_ROOT/usr/local/lib/site_perl/$i
done
