# ca_script_openssl

This Bourne Shell script uses the openssl utility to create
a certificate authority with two intermediate certificates.
It will expect the first CSR/PKCS10 to be pasted into the
terminal emulator PEM encoded. The signed certificate chain
resulting will be placed in the working directory.

sign_client_csr.sh <- This file is created on first run, it
remembers where the CA is in your file system so you can move
it to a directory in the $PATH to sign future certificates.
