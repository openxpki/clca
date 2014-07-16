# boilerplates
#
TITLE="CLCA Live Root CD"
BUILD_TIMESTAMP=`date +"%F %T%z"`
GIT_COMMIT=`git rev-list --max-count=1 HEAD`
GIT_DESCRIPTION=`git describe`

# show clca version in /etc/clca_version
cat <<EOF >$TARGETROOT/etc/clca_version
$TITLE
Built from git commit $GIT_COMMIT
Git description: $GIT_DESCRIPTION
EOF

# customize boot screen
mkdir -p config/includes/binary/isolinux

cat <<EOF >config/includes/binary/isolinux/isolinux.cfg
include menu.cfg
default vesamenu.c32
prompt 0
timeout 80
EOF

