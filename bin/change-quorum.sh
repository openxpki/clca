#!/bin/bash -e
#
# 2019-12 Martin Bartosch
# This script can assist CA Administrators in recreating a secret sharing
# quorum.

# specify old (existing) quorum
K_OLD=3
N_OLD=5

# new quorum, default: identical to old quorum
K_NEW=$K_OLD
N_NEW=$N_OLD

KEY_OLD="$1"
KEY_NEW="$2"

if [ -z "$KEY_NEW" ] ; then
cat <<EOF
Usage:
$0 OLD_KEY_FILE NEW_KEY_FILE

This script will recreate a share set and write a copy of the existing
private key KEY_OLD_FILE to the file KEY_NEW_FILE.
The script will not overwrite KEY_NEW_FILE if the file already exists.
The private key in KEY_NEW_FILE will be identical to KEY_OLD_FILE but it will
be encrypted with a different random passphrase determined by the new
quorum.
After verifying that KEY_NEW_FILE can be used with the newly created quorum
it can be used instead of KEY_OLD_FILE.

Assumptions:
- the existing quorum and the new quorum are defined in this script
  (edit below settings to reflect the actual setup)
- the existing private key is protected with the old quorum

EOF
exit 0
fi

# assert that secret is in $PATH
type secret
type openssl

if [ ! -r "$KEY_OLD" ] ; then
    echo "Old key $KEY_OLD not readable."
    exit 1
fi
if [ -e "$KEY_NEW" ] ; then
    echo "New key $KEY_NEW already exists, refusing to overwrite."
    exit 1
fi


echo "Recreating secret key sharing quorum"
echo "Old quorum:"
echo "k = $K_OLD"
echo "n = $N_OLD"
echo "New quorum:"
echo "k = $K_NEW"
echo "n = $N_NEW"

echo
echo "Unlocking old $K_OLD/$N_OLD quorum (press RETURN)"
read

export PASSPHRASE=""
eval `secret get --k $K_OLD --n $N_OLD`

if [ $? != 0 ] ; then
    echo "Error unlocking old quorum."
    exit 1
fi

if [ -z "$PASSPHRASE" ] ; then
    echo "Could not unlock old quorum."
    exit 1
fi

export PASSPHRASE_OLD="$PASSPHRASE"

clear
echo
echo "Creating new $K_NEW/$N_NEW quorum (press RETURN)"
read

eval `secret generate --k $K_NEW --n $N_NEW`

openssl pkey -in $KEY_OLD -out $KEY_NEW -passin env:PASSPHRASE_OLD -aes256 -passout env:PASSPHRASE

if [ $? != 0 ] ; then
    echo "Error: could not re-encrypt private key"
    exit 1
fi


