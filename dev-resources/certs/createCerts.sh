#!/usr/bin/env bash

set -e

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
LGREY='\e[37m'
DGREY='\e[90m'
NC='\033[0m' # No Color

error_exit() {
    local -r msg="$1"

    echo -e "${msg}"
    exit 1
}

check_for_installed_binary() {
    local -r binary_name=$1
    command -v ${binary_name} 1>/dev/null || error_exit "${GREEN}${binary_name}${RED} is not installed"
}

check_for_installed_binaries() {
    check_for_installed_binary "openssl"
    check_for_installed_binary "keytool"
}

create_ca_certs() {
    # Creating a certificate authority
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create a private key for our new CA:
    echo
    echo -e "${GREEN}Creating certificate authority private key${NC}"
    openssl genrsa \
        -out certificate-authority/ca.unencrypted.key \
        2048

    # We can then use this key to create a certificate. This asks for information about your organisation, which you can make up or just accept the defaults:
    echo
    echo -e "${GREEN}Creating certificate authority certificate${NC}"
    openssl req \
        -x509 \
        -new \
        -nodes \
        -key certificate-authority/ca.unencrypted.key \
        -sha256 \
        -days 99999 \
        -out certificate-authority/ca.pem.crt \
        -batch \
        -config ca.ssl.conf

    echo
    echo -e "${GREEN}Verifying certificate authority certificate${NC}"
    openssl x509 \
        -in certificate-authority/ca.pem.crt \
        -text \
        -noout

    # We can then optionally create a Java truststore (for use with DropWizard) from the PEM format CA certificate:
    echo
    echo -e "${GREEN}Creating certificate authority Java keystore (truststore)${NC}"
    keytool \
        -noprompt \
        -keystore certificate-authority/ca.jks \
        -importcert \
        -alias ca \
        -file certificate-authority/ca.pem.crt \
        -deststoretype JKS \
        -storepass password

}

create_server_certs() {
    # Creating the certificate for our server
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo
    echo -e "${GREEN}Creating server private key${NC}"
    openssl genrsa \
        -out server/server.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your organisation, which you can make up or just accept the defaults:
    echo
    echo -e "${GREEN}Creating server certificate signing request${NC}"
    openssl req \
        -new \
        -key server/server.unencrypted.key \
        -out server/server.csr \
        -batch \
        -config server.ssl.conf

    # Which we can sign using the CA, to get our server certificate: 
    echo
    echo -e "${GREEN}Creating server certificate${NC}"
    openssl x509 \
        -req \
        -in server/server.csr \
        -CA certificate-authority/ca.pem.crt \
        -CAkey certificate-authority/ca.unencrypted.key \
        -CAcreateserial \
        -out server/server.pem.crt \
        -days 99999 \
        -sha256

    echo
    echo -e "${GREEN}Verifying server certificate${NC}"
    openssl x509 \
        -in server/server.pem.crt \
        -text \
        -noout

    # The server then needs the CA's cert (`ca.pem.crt`), it's own cert (`server.pem.crt`) and it's own private key (`server.unencrypted.key`).

    # We can optionally create a Java keystore (for use with DropWizard) from the PEM format certificate and private key (going via a PKCS12 file):
    echo
    echo -e "${GREEN}Creating server PKCS12 store${NC}"
    openssl pkcs12 \
        -export \
        -in server/server.pem.crt \
        -inkey server/server.unencrypted.key \
        -out server/server.p12 \
        -name server \
        -CAfile certificate-authority/ca.pem.crt \
        -caname root \
        -passout pass:password

    echo
    echo -e "${GREEN}Creating server Java keystore${NC}"
    keytool \
        -importkeystore \
        -deststorepass password \
        -destkeypass password \
        -destkeystore server/server.jks \
        -deststoretype JKS \
        -srckeystore server/server.p12 \
        -srcstoretype PKCS12 \
        -srcstorepass password \
        -alias server
}

create_client_certs() {
    # Creating the certificate for our client
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo
    echo -e "${GREEN}Creating client private key${NC}"
    openssl genrsa \
        -out client/client.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your organisation, which you can make up or just accept the defaults:
    echo
    echo -e "${GREEN}Creating client certificate signing request${NC}"
    openssl req \
        -new \
        -key client/client.unencrypted.key \
        -out client/client.csr \
        -batch \
        -config client.ssl.conf

    # Which we can sign using the CA, to get our client certificate: 
    echo
    echo -e "${GREEN}Creating client certificate${NC}"
    openssl x509 \
        -req \
        -in client/client.csr \
        -CA certificate-authority/ca.pem.crt \
        -CAkey certificate-authority/ca.unencrypted.key \
        -CAcreateserial \
        -out client/client.pem.crt \
        -days 99999 \
        -sha256

    echo
    echo -e "${GREEN}Verifying client certificate${NC}"
    openssl x509 \
        -in client/client.pem.crt \
        -text \
        -noout

    # The client then needs the CA's cert (`ca.pem.crt`), it's own cert (`client.pem.crt`) and it's own private key (`client.unencrypted.key`).

    # We can optionally create a Java keystore (for use with DropWizard) from the PEM format certificate and private key (going via a PKCS12 file):
    echo
    echo -e "${GREEN}Creating client PKCS12 store${NC}"
    openssl pkcs12 \
        -export \
        -in client/client.pem.crt \
        -inkey client/client.unencrypted.key \
        -out client/client.p12 \
        -name client \
        -CAfile certificate-authority/ca.pem.crt \
        -caname root \
        -passout pass:password

    echo
    echo -e "${GREEN}Creating client Java keystore${NC}"
    keytool \
        -importkeystore \
        -deststorepass password \
        -destkeypass password \
        -destkeystore client/client.jks \
        -deststoretype JKS \
        -srckeystore client/client.p12 \
        -srcstoretype PKCS12 \
        -srcstorepass password \
        -alias client

}

delete_existing_certs() {
    echo
    echo -e "${GREEN}Deleting existing files${NC}"
    rm -f ${SCRIPT_DIR}/certificate-authority/ca.*
    rm -f ${SCRIPT_DIR}/client/client.*
    rm -f ${SCRIPT_DIR}/server/server.*
}

main() {

    check_for_installed_binaries

    #Get the dir that this script lives in, no matter where it is called from
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    delete_existing_certs

    create_ca_certs

    create_server_certs

    create_client_certs

    echo
    echo -e "${GREEN}Done!${NC}"
}

main $@
