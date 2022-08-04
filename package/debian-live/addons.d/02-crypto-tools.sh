# additional packages for this addon
PACKAGES="$PACKAGES openssl"

# optional packages - useful for certain hardware tokens
# smartcard support
PACKAGES="$PACKAGES opensc libccid libengine-pkcs11-openssl"
# pkcs11 support
PACKAGES="$PACKAGES gnutls-bin"
# yubikey personalization
PACKAGES="$PACKAGES yubikey-personalization yubikey-personalization-gui"
#PACKAGES="$PACKAGES yubico-piv-tool ykcs11"
# gnupg-agent
PACKAGES="$PACKAGES gnupg-agent"

# Java
PACKAGES="$PACKAGES default-jre-headless libbcprov-java"

