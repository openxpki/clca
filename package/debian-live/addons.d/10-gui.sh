# additional packages for this addon
PACKAGES="$PACKAGES openbox chromium xorg"
PACKAGES="$PACKAGES mupdf xli"
# I am an emacs guy
PACKAGES="$PACKAGES emacs"

# create system autostart for openbox

    mkdir -p $TARGETROOT/etc/xdg/openbox
    cat <<EOF >$TARGETROOT/etc/xdg/openbox/autostart

# load background image if available in user home
if [ -f ~/.xrootimage.png ] ; then
    xli -onroot -fillscreen ~/.xrootimage.png
fi

# Open browser if index.html is provided
if [ -f ~/htdocs/index.html ]; then
  chromium ~/htdocs/index.html &
fi

# Open terminal
xterm &

EOF


# create user template for openbox

    cat <<EOF >$TARGETROOT/etc/xdg/openbox/user-autostart-template

# Users openbox autostart file
# Add custom openbox autostart in this file

EOF


# prepare user's wm startup

    mkdir $TARGETROOT/etc/profile.d
    cat <<EOF >$TARGETROOT/etc/profile.d/gui-setup.sh
#!/bin/sh -e

if [ ! -d ~/.config/openbox ] ; then
    mkdir -p ~/.config/openbox
    cp /etc/xdg/openbox/user-autostart-template ~/.config/openbox/autostart
    chown -R $LOGNAME ~/.config
fi
EOF

chmod 755 $TARGETROOT/etc/profile.d/gui-setup.sh
