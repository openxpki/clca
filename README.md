# clca - command line CA

Copyright (c) 2004 - 2026 Martin Bartosch, White Rabbit Security GmbH

clca is distributed under the GNU General Public License, see `LICENSE`.

## Overview

clca is a command line Certificate Authority for offline CAs: a bash script
around `openssl ca` that covers the life cycle of a CA. It creates the CA
certificate (self-signed or as a request to a higher CA), signs certificate
requests, revokes certificates, issues CRLs, and keeps the CA database. It was
designed for Root CAs, but works for any offline CA.

The repository contains three tools:

- `bin/clca`: the CA itself.
- `bin/secret`: Shamir's Secret Sharing. Splits the passphrase of a CA key into
  *n* shares, of which any *k* are needed to use the key.
- `bin/provision`: creates CA instance directories from templates (YAML and
  Template Toolkit).

CA private keys can be kept in passphrase protected files (optionally with the
passphrase split by `secret`), or in an HSM through an OpenSSL engine or an
OpenSSL 3 provider (for example PKCS#11).

clca does not support concurrent use: never run two clca commands on the same
CA at the same time.

## Requirements

- Linux with bash and the GNU core utilities
- OpenSSL (OpenSSL 3 for the provider support)
- Perl for `secret` (uses the modules in `lib/`) and for `provision`
  (Template Toolkit, YAML)

## Installation

clca needs no installation: run `bin/clca` from the repository, or copy `bin/`
and `lib/` to a directory of your choice (for example `/usr/local`) and put
`bin` into your `PATH`.

## Quick start: a Root CA with a software key

Every CA is a directory (a "CA instance") with its own configuration in `etc/`.
clca always works on the CA instance in the current directory.

```sh
mkdir rootca
cd rootca
mkdir etc
cp /path/to/clca/etc/clca.cfg /path/to/clca/etc/openssl.cnf etc/
```

Adapt the configuration:

- `etc/clca.cfg`: key storage (`ENGINE`, `ROOTKEYNAME`), defaults for new keys,
  CA validity (see "Configuration").
- `etc/openssl.cnf`: the CA's distinguished name (section `[ root_dn ]`), the
  extensions of the CA certificate (`[ root_ext ]`), of CRLs and of the
  certificates the CA issues (certificate profiles, see below).

Create the CA key. `genkey` asks for the new passphrase and writes
`private/cakey.pem` (RSA 3072 bit by default, see `DEFAULT_*` in `clca.cfg`):

```sh
clca genkey
```

Create the CA: a self-signed certificate valid from 2026-10-09 to 2036-10-09
(dates in UTC, see "Dates"):

```sh
clca initialize --startdate 261009 --enddate 361009
```

For a Sub CA, create a request instead and have it certified by the higher CA:

```sh
clca initialize --req subca.csr
```

Then issue the first CRL:

```sh
clca issuecrl
```

The CRL is written to `crl/YYYYMMDDHHMMSS.crl`; `crl/ca.crl` points to the
latest one.

## Daily operation

Sign a certificate request (PEM or DER) with the certificate profile
`endentity` of the sample `openssl.cnf`:

```sh
clca certify --profile endentity --out cert.pem request.csr
```

`clca certify` without `--profile` lists the profiles of the CA. Use explicit
`--startdate` and `--enddate` for CA certificates. `--subject` replaces the
subject of the request, `--san TYPE:VALUE` adds Subject Alternative Names, and
`--reqformat SSCERT|KEY` certifies a self-signed certificate or a key instead of
a request (see `clca help certify`).

List the certificates (all, `valid` or `revoked`):

```sh
clca list valid
```

Revoke a certificate and issue a new CRL:

```sh
clca revoke --reason superseded cert.pem
clca issuecrl
```

With `RANDOMIZE_SERIAL=1` (default), certificates are revoked by their file,
not by serial number. Reasons: `unspecified`, `keyCompromise`, `CACompromise`,
`affiliationChanged`, `superseded`, `cessationOfOperation`;
`--compromisetime YYYYMMDDHHMMSSZ` records the time of a compromise.

Other commands:

| Command | Purpose |
|---|---|
| `clca login` | asks for the CA key passphrase once and opens a shell in which clca commands use it |
| `clca backup [FILE]` | writes a tar archive of the CA instance (database, configuration, key files) |
| `clca check` | shows checksums of the configuration and of the external programs clca uses |
| `clca genkey [OPTIONS]` | creates a key pair (also for end entities, `--keyfile`) |
| `clca help [COMMAND]` | lists the commands, or shows the help of one command |

Keep a backup of every CA instance after every change: without the key and
the database, the CA can issue no more certificates or CRLs.

## Dates

`--startdate` and `--enddate` take a DATESPEC in UTC:

- the truncated format `YY[MM[DD[HH[MM[SS]]]]]`, for example `2610` for
  2026-10-01 00:00:00. Omitted parts get their lowest value. Only for years up to
  2049;
- the complete format `YYYYMMDDHHMMSS`, for any year.

See `clca help datespec`.

## Configuration

`etc/clca.cfg` is a bash file read by every clca command. The main settings:

| Setting | Meaning |
|---|---|
| `ENGINE` | where the CA key lives: `openssl` (key file), `pkcs11` (PKCS#11 engine), `chil` (nCipher engine), `gem` (Luna engine), `provider` (OpenSSL 3 providers) |
| `ROOTKEYNAME` | the CA key: a file name in `private/` (`openssl`), a key identifier or PKCS#11 URI (engines, `provider`) |
| `OPENSSL` | the `openssl` binary |
| `OPENSSL_PROVIDERS` | OpenSSL 3 providers to load for every OpenSSL call (bash array), e.g. `( default pkcs11 )` |
| `HSM_PRELOAD` | wrapper command for HSM key operations (e.g. nCipher `preload`) |
| `DEFAULT_PUBKEY_ALGORITHM`, `DEFAULT_RSA_KEYSIZE`, `DEFAULT_EC_CURVE`, `DEFAULT_ENC_ALGORITHM` | defaults of `genkey` |
| `CA_VALIDITY` | validity of a CA certificate in days if no dates are given |
| `RANDOMIZE_SERIAL` | random certificate serial numbers |
| `BATCH` | do not ask for confirmation before signing |

Certificate profiles are sections of `etc/openssl.cnf` that contain
`x509_extensions` and neither `crl_extensions` nor `distinguished_name`.
clca adjusts the paths in `openssl.cnf` itself.

### Passphrases

By default clca asks for the passphrase of the CA key on the terminal. To get
it differently, define a function `get_passphrase` in `clca.cfg` that prints
it. With secret sharing (see below):

```sh
get_passphrase() {
    eval `secret get --n 5 --k 3`
    echo $PASSPHRASE
}
```

If `get_passphrase` prints nothing, no passphrase is passed to OpenSSL (the HSM
or OpenSSL asks itself, or the key needs none).

### HSM keys

- **PKCS#11 engine:** `ENGINE=pkcs11` and `ROOTKEYNAME` set to the key's PKCS#11
  URI or identifier. The key is generated with the HSM's tools.
- **OpenSSL 3 provider:** `ENGINE=provider`, `OPENSSL_PROVIDERS=( default pkcs11 )`,
  `ROOTKEYNAME='pkcs11:token=RootCA;object=rootca1;type=private'`, and
  `export PKCS11_PROVIDER_MODULE=/path/to/the/hsm/pkcs11/library.so` in
  `clca.cfg`. The provider can use any algorithm the HSM supports. clca asks for
  the token PIN as the passphrase.
- **nCipher (chil) and Luna (gem) engines:** `ENGINE=chil` or `ENGINE=gem`,
  following the vendor's OpenSSL engine documentation.

### Extensions

- A function `custom_NAME` in `clca.cfg` adds a command `clca NAME`. It must
  print a description for `--shorthelp` and its usage for `--help`.
- `hook_init` and `hook_exit` in `clca.cfg` run before and after every command
  of this CA instance.
- Executables in `/etc/clca/hooks.d/pre-command.d/` and `post-command.d/`
  (`CLCA_HOOK_DIR`) run for every command of every CA instance on the host,
  with `CLCA_COMMAND`, `CA_HOME` and (after the command) `CLCA_EXIT_CODE` in
  their environment. A failing pre-command hook aborts the command.

## Secret sharing

`secret` protects the passphrase of a CA key with Shamir's Secret Sharing. A key
ceremony with 3 of 5 share holders:

```sh
eval `secret generate --n 5 --k 3` openssl genrsa -aes256 -passout env:PASSPHRASE -out private/cakey.pem 3072
```

`secret generate` creates a random passphrase and prints the shares one by one;
each share holder copies and keeps one share. The passphrase is passed to the
command after it (here: the key generation) and is never shown. Later,
`secret get --n 5 --k 3` asks for three shares and reconstructs the passphrase
(use it in `get_passphrase`, see above). With `--encrypted-shares --share-dir
DIR`, each share is stored in a file encrypted with its holder's own passphrase.
See `secret --man`.

## Provisioning

`provision` renders CA instance directories from a template configuration
(`--template NAME`, YAML files in `etc/templates`), with values from the
template and from the command line (`--set KEY:VALUE`). This keeps many CA
instances consistent and makes rollovers repeatable. See `provision --help`.
