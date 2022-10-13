# install optional contributions

# modify boot logo if splash.svg or splash.png (640x480 png image) exists in contrib
if [ -r contrib/splash.svg -o -r contrib/splash.png ] ; then
    mkdir -p config/bootloaders
    cp -a /usr/share/live/build/bootloaders/syslinux* config/bootloaders/
    rm config/bootloaders/syslinux_common/splash.*
    cp contrib/splash.{svg,png} config/bootloaders/syslinux_common/
fi
