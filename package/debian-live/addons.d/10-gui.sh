# additional packages for this addon
PACKAGES="$PACKAGES openbox chromium xorg"
PACKAGES="$PACKAGES mupdf xli"
# I am an emacs guy
PACKAGES="$PACKAGES emacs"

# files to install

    mkdir -p $TARGETROOT/etc/xdg/openbox
    cat <<EOF >$TARGETROOT/etc/xdg/openbox/autostart
# Starting terminal
xterm &

# Open browser if index.html is provided
if [ -f ~/htdocs/index.html ]; then
  chromium ~/htdocs/index.html &
fi

# load background image if available in user home
if [ -f ~/.xrootimage.png ] ; then
    xli -onroot -fillscreen ~/.xrootimage.png
fi
EOF

# prepare user's wm startup
    cat <<EOF >$TARGETROOT/etc/rc.local.d/gui-setup
#!/bin/sh -e

if [ ! -d /home/$USERNAME/.config/openbox ] ; then
    mkdir -p /home/$USERNAME/.config/openbox
    cp /etc/xdg/openbox/autostart /home/$USERNAME/.config/openbox/
    chown -R $USERNAME /home/$USERNAME/.config
fi
EOF

chmod 755 $TARGETROOT/etc/rc.local.d/gui-setup

