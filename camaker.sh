#!/bin/sh
# This script builds a CA chain and signs one PEM/Base64
# encoded certificate expected on STDIN.
KEY_LENGTH=2048
DAYS=365
create_env ()
{
	mkdir ca
	cd ca
	mkdir -p certs \
	         crl \
	         newcerts \
	         private \
		 ca \
		 intermediate
	chmod 700 private
	touch index.txt
	if [ ! -f serial ]; then
	    echo 1000 > serial
	fi
	
	mkdir ../intermediate
	cd ../intermediate
	mkdir -p certs \
	         crl \
	         csr \
	         newcerts \
	         private
	chmod 700 private
	touch index.txt
	if [ ! -f serial ]; then
	    echo 1000 > serial
	fi
	if [ ! -f crlnumber ]; then
	    echo 1000 > crlnumber
	fi
        cd ../
}
clean()
{
	if [ $1 = "confirm" ]
	then
	    rm -rf ca/index.txt \
	           ca/serial \
	           ca/certs \
	           ca/private \
	           intermediate/index.txt \
	           intermediate/serial \
	           intermediate/certs \
	           intermediate/private \
	           intermediate/csr
	else
	    echo "Must confirm"
	    echo "usage: ./clean.sh confirm"
	fi
}
echo Creating directory structure and configuration files.
if [ -d ca/serial ]
then
	clean
fi
create_env


## Create Root CA config file.
(
more << 'EOF'
# Modified from https://jamielinux.com/docs/openssl-certificate-authority/_downloads/root-config.txt

# OpenSSL root CA configuration file.
# Copy to `/root/ca/openssl.cnf`.

[ ca ]
# `man ca`
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ./ca
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/ca.key
certificate       = $dir/certs/ca.crt

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of `man ca`.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the `ca` man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the `req` tool (`man req`).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = California
localityName_default            = San Diego
0.organizationName_default      = Example Org
organizationalUnitName_default  =
commonName_default              = CA Root Example
emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA (`man x509v3_config`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (`man x509v3_config`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:1
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (`man x509v3_config`).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (`man x509v3_config`).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (`man x509v3_config`).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (`man ocsp`).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
) > ca.cnf


## Create first intermediate CA config file.
(
more << 'EOF'
# Modified from https://jamielinux.com/docs/openssl-certificate-authority/_downloads/root-config.txt

# OpenSSL root CA configuration file.
# Copy to `/root/ca/openssl.cnf`.

[ ca ]
# `man ca`
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ./intermediate
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/intermediate.key
certificate       = $dir/certs/intermediate.crt

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of `man ca`.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the `ca` man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the `req` tool (`man req`).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = California
localityName_default            = San Diego
0.organizationName_default      = Example Org
organizationalUnitName_default  =
commonName_default              = CA Intermediate 0 Example
emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA (`man x509v3_config`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (`man x509v3_config`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:1
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (`man x509v3_config`).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (`man x509v3_config`).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (`man x509v3_config`).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (`man ocsp`).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
) > intermediate.cnf


## Create second intermediate CA config file
(
more << 'EOF'
# Modified from https://jamielinux.com/docs/openssl-certificate-authority/_downloads/root-config.txt

# OpenSSL root CA configuration file.
# Copy to `/root/ca/openssl.cnf`.

[ ca ]
# `man ca`
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ./intermediate
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/intermediate2.key
certificate       = $dir/certs/intermediate2.crt

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

copy_extensions = copy # Copy extensions from request

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = yes
email_in_dn       = no # Don't add the email into cert DN
policy            = policy_any

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of `man ca`.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the `ca` man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional


[ policy_any ]
domainComponent        = optional
userId                 = optional
countryName            = supplied
postalCode             = optional
stateOrProvinceName    = optional
streetAddress          = optional
postOfficeBox          = optional
organizationName       = optional
organizationalUnitName = optional
title                  = optional
surname                = optional
initials               = optional
givenName              = optional
commonName             = supplied
telephoneNumber        = optional
emailAddress           = optional

[ req ]
# Options for the `req` tool (`man req`).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     = California
localityName_default            = San Diego
0.organizationName_default      = Example Org
organizationalUnitName_default  =
commonName_default              = CA Intermatiate 1 Example
emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA (`man x509v3_config`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (`man x509v3_config`).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (`man x509v3_config`).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (`man x509v3_config`).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (`man x509v3_config`).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (`man ocsp`).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
) > intermediate2.cnf

create_ca()
{
	if [ -z $KEY_LENGTH ]; then
	    echo "Must provide key length"
	    usage
	fi
	
	if [ -z $DAYS ]; then
	    echo "Must provide certificate validity in days"
	    usage
	fi
	
	# Create the root CA key and cert
	openssl req -config ca.cnf -x509 -newkey rsa:$KEY_LENGTH -nodes -keyout ca/private/ca.key -out ca/certs/ca.crt -days $DAYS
	chmod 400 ca/private/ca.key
	chmod 444 ca/certs/ca.crt
}

create_intermediate()
{
	if [ -z $KEY_LENGTH ]; then
	    echo "Must provide key length"
	    usage
	fi
	
	if [ -z $DAYS ]; then
	    echo "Must provide certificate validity in days"
	    usage
	fi
	
	# Create intermediate key
	openssl genrsa -out intermediate/private/intermediate.key $KEY_LENGTH
	chmod 400 intermediate/private/intermediate.key
	
	# Create intermediate certificate request
	openssl req -config intermediate.cnf -new -sha256 -key intermediate/private/intermediate.key -out intermediate/csr/intermediate.csr
	
	# Sign the intermediate certificate
	openssl ca -config ca.cnf -extensions v3_intermediate_ca -days $DAYS -notext -md sha256 -in intermediate/csr/intermediate.csr -out intermediate/certs/intermediate.crt
	chmod 444 intermediate/certs/intermediate.crt
}

create_intermediate2()
{
	# Create intermediate key
	openssl genrsa -out intermediate/private/intermediate2.key $KEY_LENGTH
	chmod 400 intermediate/private/intermediate2.key
	
	# Create intermediate certificate request
	openssl req -config intermediate2.cnf -new -sha256 -key intermediate/private/intermediate2.key -out intermediate/csr/intermediate2.csr
	
	# Sign the intermediate certificate
	openssl ca -config intermediate.cnf -extensions v3_intermediate_ca -days $DAYS -notext -md sha256 -in intermediate/csr/intermediate2.csr -out intermediate/certs/intermediate2.crt
	chmod 444 intermediate/certs/intermediate2.crt
}


## Sign PKCS10 as Certificate, output P7b bundle.
echo "#!/bin/sh" >> sign_client_csr.sh
echo "CAPREFIX=`pwd`" >> sign_client_csr.sh
(
more << 'EOF'

SWD=`pwd`

usage()
{
    echo "usage: ./sign_client_csr.sh <FILENAME> <DAYS>"
    exit 1
}

if [ $# -gt 1]
then
	FILENAME=$1
	DAYS=$2
fi

if [ $# -eq 1]
then
	DAYS=$1
fi

cd "$CAPREFIX"
if [ -z $FILENAME ]; then
	FILENAME=userchain
	echo "Paste PEM/Base64 encoded PKCS10/CSR to" \
	"terminal/STDIN"
	echo "^D when finished pasting:"
	cat > intermediate/csr/$FILENAME.pem
fi

if [ -z $DAYS ]; then
    echo "Must provide certificate validity in days"
    usage
fi

# Create certificate
openssl ca \
	-config intermediate2.cnf \
	-extensions usr_cert \
	-days $DAYS \
	-notext \
	-md sha256 \
	-in intermediate/csr/$FILENAME.pem \
	-out intermediate/certs/$FILENAME.crt
chmod 444 intermediate/certs/$FILENAME.crt
openssl crl2pkcs7 \
	-outform DER \
	-inform PEM \
	-out intermediate/certs/$FILENAME.p7b \
	-certfile intermediate/certs/$FILENAME.crt \
	-certfile intermediate/certs/intermediate2.crt \
	-certfile intermediate/certs/intermediate.crt \
	-certfile ca/certs/ca.crt \
	-nocrl
mv intermediate/certs/$FILENAME.p7b "$SWD"/
cd "$SWD"
openssl pkcs7 -print_certs -inform DER \
	-in "$FILENAME".p7b \
	| sed '/^subject/d' | sed '/^issuer/d' |
	sed '/^$/d' > "$FILENAME".pem
echo DER Encoded bundle "$FILENAME".p7b
echo PEM Encoded bundle "$FILENAME".pem
EOF
) >> sign_client_csr.sh

chmod 0700 sign_client_csr.sh

echo "Building Certificate Authorities"

create_ca
create_intermediate
create_intermediate2
./sign_client_csr.sh 365
