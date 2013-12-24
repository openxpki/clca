# additional packages for this addon
PACKAGES="$PACKAGES openbox chromium xorg"

# files to install

    mkdir -p $TARGETROOT/etc/.config/openbox
    cat <<EOF >$TARGETROOT/etc/.config/openbox/autostart
# Starting terminal
xterm &

# Open browser if index.html is provided

if [ -f "/home/$USERNAME/htdocs/index.html" ]; then
  chromium /home/$USERNAME/htdocs/index.html &
fi
EOF
