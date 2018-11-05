# CLCA command line CA script
Copyright (c) 2004 - 2018 Martin Bartosch, WhiteRabbitSecurity GmbH

This software is distributed under the GNU General Public License - see the
accompanying LICENSE file for more details.

## Introduction
This is a collection of tools that allow for basic PKI 
operations such as Sub CA certificate issuance (signing certificate 
requests), certificate revocation and CRL issuance.
The script was originally designed to be used for a Root CA, but may 
also be used for lower level CAs or even end entity certificates as well.

CA private keys can be held either in encrypted files (encrypted either with
a simple passphrase or using Shamir's Secret Sharing) or stored in an HSM.

The script was successfully tested with 
- Thales nCipher nShield HSM
- Gemalto SafeNet Luna SA HSM

Please note that this script does not support concurrent use of 
multiple sessions. Unpredictable behaviour must be expected if two 
instances of the CA script are run concurrently.


## Quick start: CA creation

You can handle an arbitrary number of CA instances using this script.

* For each CA create a new top level directory and change into this
  directory. Within this directory create an 'etc' directory and copy
  the contents of the sample etc directory from the CLCA distribution.

* Modify CA configuration `etc/clca.cfg` to reflect your needs. Set
  ENGINE as required for HSM or software CA support.

* Modify `etc/openssl.cnf` according to your CA policy and certificate
  profile (see "Configuration")

* Create root key (see "Root key generation")

* Create self-signed CA certificate    OR
* Create CA certificate request, export it to higher level CA and import
  the certified CA certificate




## Root key generation

Only required for nCipher HSM support:
- Install nCipher module and software.
- Create a Security World
- Create an administrator card set
- Create an operator card set that protects your root key
- Create a root key using `generatekey2 hwcrhk`

Only required for Gemalto SafeNet Luna SA HSM support:
- Install HSM drivers
- Establish trust link to Luna SA HSM
- Obtain Gamalto SafeNet support document DOW4073 (or newer document containing the OpenSSL 
  gem engine)
- Install OpenSSL Engine and sautil command line tool


Only required for software CA support with simple passphrase:
- create a `private` directory in `$CA_HOME`
- adapt the RSA key name in `clca.cfg`
- run `openssl genrsa -des3 $CA_HOME/private/<keyname>`

See [README.keyceremony-shared-interactive.md]() for an example using Secret Sharing.

## Configuration

Edit `etc/clca.cfg` and `etc/openssl.cnf` to reflect your needs, 
particularly certificate profile and other policy settings.

Please note that CA initialization takes care of setting the 
proper paths in openssl.cnf, so no manual modification is 
needed for this section.


## Basic usage and getting help

The CA system is contained in one single script (`bin/clca`). If
called without arguments it prints an overview on the supported
commands. In order to get online help about a certain command use

`$ clca help COMMAND`
or
`$ clca COMMAND --help`



## PIN entry

If a HSM is used the PIN entry is usually handled by a preload command
that calls OpenSSL in turn. Thus the configuration variable HSM_PRELOAD
must set to the appropriate executable that allows to open the HSM
for private key operations.


## CA initialization

Before the system an be used the CA must be created. This is necessary
only once.

For initial setup of a new CA the necessary steps are:

Verify if the `etc/clca.cfg` and `etc/openssl.cnf` settings are OK.

Run

`$ clca initialize --startdate YYMMDDHHMMSS --enddate YYMMDDHHMMSS`

The script performes several sanity checks and refuses to overwrite
an existing CA. If the CA certificates have been manually removed
from the `ca/` directory the existing CA is automatically backed up
to the directory `attic/` and a new CA is created.

Startdate and enddate are specified in UTC time zone. Note that the
year must be specified with two digits only!

Unless you are using a HSM you will be prompted to enter 
the PINs protecting the CA private key during the creation of the CA.

Once a CA has been set up, be sure to backup the CA key and the
certificate database. If the key is lost no new certificates or CRLs
can be issued.




## Signing certificate requests

Call

`$ clca certify --profile PROFILE [--startdate YYMMDDHHMMSS --enddate YYMMDDHHMMSS] <request file>`

in order to certify a PKCS #10 request. The request format (DER/PEM)
is automatically detected.

Please note that the `--profile` is mandatory and must reference a section in the openssl.cnf
file which contains an x509_extensions reference and does NOT contain a distinguished_name or
crl_extensions reference.

It is possible to override the Subject DN and add SubjectAlternativeNames to the request.
Refer to the command help text for details.

The startdate and enddate options are optional and are specified in UTC time zone. 
Note that the year must be specified with two digits only!
If no startdate/enddate is specified the default validity from the profile is used.

Omitting startdate and enddate is only recommended for end entity certificates, 
use the explicit validity for any certificate that is used as a CA.

The resulting certificate is placed in the certs/ directory. A copy
of the most current certificate is also written to newcert.pem in the
current working directory.



## Revoking certificates

In order to revoke a certificate call

`$ clca revoke <serial number>`

This will identify the certificate in the certificate database (certs/
directory) and mark the certificate as revoked.


## Listing certificates

Calling 

`$ clca list <filter>`

lists all certificates matching the specified filter. Filter may
be empty or either 'valid' or 'revoked'.
If no filter is specified, all certificates are printed to standard out,


## Issuing CRLs

For creating a new CRL run

`$ clca issue_crl`

This will create a new CRL and write it to the directory 
`crls/YYYYMMDDHHMMSS.crl`. (The capital letters are replaced with
the current time stamp.)

The CRL validity is configured in the etc/openssl.cnf file.


## Checking software integrity

Integrity checks of the configuration and all required external programs
can be performed by running

`$ clca check`

This command will report individual check sums for the configuration
files and one compound checksum over all external UNIX utilities
used by the script.

## Creating CA backups

At any time it is possible to create a snapshot of the current CA status,
including the certificate database, revocation state and all related
data (including private keys if no HSM is used).

To create such a backup simply run

`$ clca backup [filename]`

This will create a gzip compressed tar backup in the current directory
named `YYYYMMDDHHMMSS-ca-backup.tar.gz` if no filename is specified,
otherwise it will create the specified file.

This backup contains all information to recover the CA to the 
state it was in when the backup command was run. To recover to this
point simply erase the `$CA_HOME` directory and extract the desired
backup archive. This will restore configuration file, ca executable
and certificate database.

