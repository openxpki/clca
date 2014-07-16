# show clca version in /etc/clca_version
echo "CLCA Live Root CD" >$TARGETROOT/etc/clca_version
echo -n "Built from git commit " >>$TARGETROOT/etc/clca_version
git rev-list --max-count=1 HEAD >>$TARGETROOT/etc/clca_version
echo -n "Git description: " >>$TARGETROOT/etc/clca_version
git describe >>$TARGETROOT/etc/clca_version
