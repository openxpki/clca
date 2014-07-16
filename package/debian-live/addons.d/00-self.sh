# additional packages for this addon
PACKAGES="$PACKAGES live-build git"

# create a git bundle, deploy it on target system and "check out" current
# branch in target dir

CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
ORIGIN="https://github.com/openxpki/clca.git"

mkdir -p $TARGETROOT/usr/src/
git bundle create $TARGETROOT/usr/src/clca.bundle --all

( cd $TARGETROOT/usr/src/ && 
  git clone clca.bundle &&
  cd clca &&
  git remote add github $ORIGIN &&
  git checkout $CURRENT_BRANCH )

# clean origin: remove build path prefix
perl -i -p -e "s|`pwd`/config/includes.chroot||" $TARGETROOT/usr/src/clca/.git/config

# show clca version in /etc/clca_version
echo "CLCA Live Root CD" >$TARGETROOT/etc/clca_version
echo -n "Built from git commit " >>$TARGETROOT/etc/clca_version
git rev-list --max-count=1 HEAD >>$TARGETROOT/etc/clca_version
echo -n "Git description: " >>$TARGETROOT/etc/clca_version
git describe >>$TARGETROOT/etc/clca_version


