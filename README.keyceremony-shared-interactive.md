# Interactive Secret Sharing CA runbook example
This is an example runbook for an interactive key ceremony using Secret Sharing.

2013-12-16 Martin Bartosch

# Creation of a secret share set and CA initialization

Assumptions:
2048 Bit RSA key protected by a 128 Bit random pass phrase.
The pass phrase is split into 5 shares, of which 3 will be needed to perform CA operations.



```
1. Preparation of CLCA configuration

export K=3
export N=5
rm -rf dummyca/
mkdir -p dummyca/etc
mkdir -p dummyca/private/
chmod 700 dummyca/private/
cp etc/clca.cfg dummyca/etc/
cp etc/openssl.cnf dummyca/etc/

cat <<EOF >>dummyca/etc/clca.cfg
get_passphrase() {
   eval \`../bin/secret get --n $N --k $K\`
   echo \$PASSPHRASE
}
EOF

2. Generate CA key and perform secret sharing.

Required: you need N=5 persons for safekeeping of the CA shares.

eval `./bin/secret generate  --n $N --k $K` openssl genrsa -aes256 -passout env:PASSPHRASE -out dummyca/private/rsa-rootkey 2048

Each share holder must copy the displayed share literally and keep it.

3. Create the CA certificate

cd dummyca
../bin/clca initialize

4. Create initial CRL

../bin/clca issuecrl

5. Sign certificate

../bin/clca certify --profile foo REQUEST


```



## Replacing a secret share set

If a share gets lost or if the existing quorum should be changed to a different one, it is possible to recreate the secret share set with a completely different secret share set, replacing the old share set.

This is done be decrypting the private key with the old quorum and re-encrypting the key with a newly created quorum, thus also changing the underlying passphrase.

Please note that the old private key file with the old share set will still be sufficient to unlock the private key, so make sure to destroy the old set and key once it has been verified that the new share set works.

The following procedure (also available as bin/change-quorum.sh) can be applied to perform this task.

Please note that you need to edit the script to adapt old and new quorum parameters. The script will fail if these parameters are not correct.

```bash
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

openssl pkey -in $KEY_OLD -out $KEY_NEW -passin env:PASSPHRASE_OLD -passout env:PASSPHRASE

if [ $? != 0 ] ; then
    echo "Error: could not re-encrypt private key"
    exit 1
fi



```



