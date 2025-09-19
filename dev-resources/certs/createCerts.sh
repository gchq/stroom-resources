#!/usr/bin/env bash

set -eo pipefail

# https://github.com/xperseguers/ocsp-responder/blob/master/Documentation/CertificateAuthority.md
# https://gist.github.com/jadbaz/9350f4df4e4ef4c5d256889aa3d5a5ed
# https://docs.openssl.org/master/man1/openssl-ca/
# https://docs.openssl.org/master/man1/openssl-x509/
#
# ca.pem.crt
#   ocsp_responder1.pem.crt
#   server.pem.crt
#   client.pem.crt
#   intermediate_ca.pem.crt
#     ocsp_responder2.pem.crt
#     client2.pem.crt

#Shell Colour constants for use in 'echo -e'

# shellcheck disable=SC2034
{
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    LGREY='\e[37m'
    DGREY='\e[90m'
    NC='\033[0m' # No Color
}

error_exit() {
    local -r msg="$1"

    echo -e "${msg}"
    exit 1
}

check_for_installed_binary() {
    local -r binary_name=$1
    command -v "${binary_name}" 1>/dev/null \
      || error_exit "${GREEN}${binary_name}${RED} is not installed${NC}"
}

check_for_installed_binaries() {
    check_for_installed_binary "openssl"
    check_for_installed_binary "keytool"
}

create_ca_certs() {
    # Creating a certificate authority
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create a private key for our new CA:
    echo -e "${GREEN}Creating certificate authority private key${NC}"
    openssl genrsa \
        -out certificate-authority/ca.unencrypted.key \
        2048

    # We can then use this key to create a certificate. This asks for
    # information about your organisation, which you can make up or just accept
    # the defaults:
    echo -e "${GREEN}Creating certificate authority certificate${NC}"
    openssl req \
        -x509 \
        -new \
        -nodes \
        -key certificate-authority/ca.unencrypted.key \
        -sha512 \
        -days "${DAYS_TO_EXPIRY}" \
        -out certificate-authority/ca.pem.crt \
        -batch \
        -config ca.ssl.conf

    echo -e "${GREEN}Verifying certificate authority certificate${NC}"
    openssl x509 \
        -in certificate-authority/ca.pem.crt \
        -issuer \
        -subject \
        -noout
    openssl verify \
      -CAfile certificate-authority/ca.pem.crt \
      certificate-authority/ca.pem.crt

    # We can then optionally create a Java truststore (for use with DropWizard)
    # from the PEM format CA certificate:
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

create_intermediate_ca_certs() {
    # Creating an intermediate certificate authority
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create a private key for our new CA:
    echo -e "${GREEN}Creating intermediate certificate authority private key${NC}"
    openssl genrsa \
        -out intermediate-ca/intermediate_ca.unencrypted.key \
        2048
    #
    # Then we create a signing request. This asks for information about your
    # organisation, which you can make up or just accept the defaults:
    echo -e "${GREEN}Creating client2 certificate signing request${NC}"
    openssl req \
        -new \
        -key intermediate-ca/intermediate_ca.unencrypted.key \
        -out intermediate-ca/intermediate_ca.csr \
        -batch \
        -config intermediate_ca.ssl.conf

    # We can then use this key to create a certificate. This asks for
    # information about your organisation, which you can make up or just accept
    # the defaults:
    echo -e "${GREEN}Creating intermediate certificate authority certificate${NC}"
    openssl ca \
        -extensions x509_ext \
        -in intermediate-ca/intermediate_ca.csr \
        -days "${DAYS_TO_EXPIRY}" \
        -out intermediate-ca/intermediate_ca.pem.crt \
        -config intermediate_ca.ssl.conf \
        -notext \
        -batch

    # Create a CA bundle containing all CAs
    cat \
      certificate-authority/ca.pem.crt \
      intermediate-ca/intermediate_ca.pem.crt \
      > chain/ca_bundle.pem.crt

    echo -e "${GREEN}Verifying intermediate certificate authority certificate${NC}"
    openssl x509 \
        -in intermediate-ca/intermediate_ca.pem.crt \
        -issuer \
        -subject \
        -noout

    openssl verify \
      -CAfile chain/ca_bundle.pem.crt \
      intermediate-ca/intermediate_ca.pem.crt

    # We can then optionally create a Java truststore (for use with DropWizard)
    # from the PEM format CA certificate:
    echo -e "${GREEN}Creating certificate authority Java keystore (truststore) bundle${NC}"
    # Add root CA
    keytool \
        -noprompt \
        -keystore chain/ca_bundle.jks \
        -importcert \
        -alias ca \
        -file certificate-authority/ca.pem.crt \
        -deststoretype JKS \
        -storepass password

    # Add intermediate CA
    keytool \
        -noprompt \
        -keystore chain/ca_bundle.jks \
        -importcert \
        -alias intermediate_ca \
        -file intermediate-ca/intermediate_ca.pem.crt \
        -deststoretype JKS \
        -storepass password
}

copy_ca_certs() {
    cp certificate-authority/ca.pem.crt server/ca.pem.crt
    cp certificate-authority/ca.jks server/ca.jks
    cp certificate-authority/ca.pem.crt client/ca.pem.crt
    cp certificate-authority/ca.jks client/ca.jks

    cp certificate-authority/ca.pem.crt chain/ca.pem.crt
}

create_server_certs() {
    # Creating the certificate for our server
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo -e "${GREEN}Creating server private key${NC}"
    openssl genrsa \
        -out server/server.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your
    # organisation, which you can make up or just accept the defaults:
    echo -e "${GREEN}Creating server certificate signing request${NC}"
    openssl req \
        -new \
        -key server/server.unencrypted.key \
        -out server/server.csr \
        -batch \
        -config server.ssl.conf

    # Which we can sign using the CA, to get our server certificate: 
    #-signkey server/server.unencrypted.key \
    echo -e "${GREEN}Creating server certificate${NC}"
    openssl x509 \
        -extfile server.ssl.conf \
        -extensions x509_ext \
        -req \
        -in server/server.csr \
        -CA certificate-authority/ca.pem.crt \
        -CAkey certificate-authority/ca.unencrypted.key \
        -out server/server.pem.crt \
        -days "${DAYS_TO_EXPIRY}" \
        -sha512

    echo -e "${GREEN}Verifying server certificate${NC}"
    openssl x509 \
        -in server/server.pem.crt \
        -issuer \
        -subject \
        -noout
    openssl verify \
      -CAfile certificate-authority/ca.pem.crt \
      server/server.pem.crt
      

    # The server then needs the CA's cert (`ca.pem.crt`), it's own cert
    # (`server.pem.crt`) and it's own private key (`server.unencrypted.key`).

    # We can optionally create a Java keystore (for use with DropWizard) from
    # the PEM format certificate and private key (going via a PKCS12 file):
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

    # TODO Not sure if we want to add the ca cert to the keystore or not.
    keytool \
        -import \
        -keystore server/server.jks \
        -storepass password \
        -file certificate-authority/ca.pem.crt \
        -alias ca \
        -noprompt \
        -trustcacerts
}

create_client1_certs() {
    # Creating the certificate for our client
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo -e "${GREEN}Creating client private key${NC}"
    openssl genrsa \
        -out client/client.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your
    # organisation, which you can make up or just accept the defaults:
    echo -e "${GREEN}Creating client certificate signing request${NC}"
    openssl req \
        -new \
        -key client/client.unencrypted.key \
        -out client/client.csr \
        -batch \
        -config client.ssl.conf

    # Which we can sign using the CA, to get our client certificate: 
    echo -e "${GREEN}Creating client certificate${NC}"
    #openssl x509 \
        #-extfile client.ssl.conf \
        #-extensions x509_ext \
        #-req \
        #-in client/client.csr \
        #-CA certificate-authority/ca.pem.crt \
        #-CAkey certificate-authority/ca.unencrypted.key \
        #-out client/client.pem.crt \
        #-days "${DAYS_TO_EXPIRY}" \
        #-sha512
    openssl ca \
        -extensions x509_ext \
        -in client/client.csr \
        -days "${DAYS_TO_EXPIRY}" \
        -out client/client.pem.crt \
        -config client.ssl.conf \
        -notext \
        -batch

    echo -e "${GREEN}Verifying client certificate${NC}"
    openssl x509 \
        -in client/client.pem.crt \
        -issuer \
        -subject \
        -noout
    openssl verify \
      -CAfile certificate-authority/ca.pem.crt \
      client/client.pem.crt

    # The client then needs the CA's cert (`ca.pem.crt`), it's own cert
    # (`client.pem.crt`) and it's own private key (`client.unencrypted.key`).

    # We can optionally create a Java keystore (for use with DropWizard) from
    # the PEM format certificate and private key (going via a PKCS12 file):
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

create_client2_certs() {
    # Creating the certificate for our client
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo -e "${GREEN}Creating client2 private key${NC}"
    openssl genrsa \
        -out chain/client2.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your
    # organisation, which you can make up or just accept the defaults:
    echo -e "${GREEN}Creating client2 certificate signing request${NC}"
    openssl req \
        -new \
        -key chain/client2.unencrypted.key \
        -out chain/client2.csr \
        -batch \
        -config client2.ssl.conf

    # Which we can sign using the CA, to get our client certificate: 
    echo -e "${GREEN}Creating client2 certificate${NC}"
    #openssl x509 \
        #-extfile client2.ssl.conf \
        #-extensions x509_ext \
        #-req \
        #-in chain/client2.csr \
        #-CA intermediate-ca/intermediate_ca.pem.crt \
        #-CAkey intermediate-ca/intermediate_ca.unencrypted.key \
        #-out chain/client2.pem.crt \
        #-days "${DAYS_TO_EXPIRY}" \
        #-sha512
    openssl ca \
        -config client2.ssl.conf \
        -in chain/client2.csr \
        -out chain/client2.pem.crt \
        -days "${DAYS_TO_EXPIRY}" \
        -notext \
        -batch

    echo -e "${GREEN}Verifying client2 certificate${NC}"
    openssl x509 \
        -in chain/client2.pem.crt \
        -subject \
        -noout
    openssl verify \
      -CAfile chain/ca_bundle.pem.crt \
      chain/client2.pem.crt

    cat \
      "${SCRIPT_DIR}"/chain/client2.pem.crt \
      "${SCRIPT_DIR}"/intermediate-ca/intermediate_ca.pem.crt \
      > "${SCRIPT_DIR}"/chain/client2_bundle.pem.crt

    # The client then needs the CA's cert (`ca.pem.crt`), it's own cert
    # (`client2.pem.crt`) and it's own private key (`client2.unencrypted.key`).

    # We can optionally create a Java keystore (for use with DropWizard) from
    # the PEM format certificate and private key (going via a PKCS12 file):
    echo -e "${GREEN}Creating client2 PKCS12 store${NC}"
    openssl pkcs12 \
        -export \
        -in chain/client2_bundle.pem.crt \
        -inkey chain/client2.unencrypted.key \
        -out chain/client2_bundle.p12 \
        -name client2_bundle \
        -CAfile certificate-authority/ca_bundle.pem.crt \
        -caname root \
        -passout pass:password

    echo -e "${GREEN}Creating client2 Java keystore${NC}"
    keytool \
        -importkeystore \
        -deststorepass password \
        -destkeypass password \
        -destkeystore chain/client2_bundle.jks \
        -deststoretype JKS \
        -srckeystore chain/client2_bundle.p12 \
        -srcstoretype PKCS12 \
        -srcstorepass password \
        -alias client2_bundle

}

create_client_revoked_certs() {
    # Creating the certificate for our client
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo -e "${GREEN}Creating client_revoked private key${NC}"
    openssl genrsa \
        -out chain/client_revoked.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your
    # organisation, which you can make up or just accept the defaults:
    echo -e "${GREEN}Creating client_revoked certificate signing request${NC}"
    openssl req \
        -new \
        -key chain/client_revoked.unencrypted.key \
        -out chain/client_revoked.csr \
        -batch \
        -config client_revoked.ssl.conf

    # Which we can sign using the CA, to get our client certificate: 
    echo -e "${GREEN}Creating client_revoked certificate${NC}"
    openssl ca \
        -config client_revoked.ssl.conf \
        -in chain/client_revoked.csr \
        -out chain/client_revoked.pem.crt \
        -days "${DAYS_TO_EXPIRY}" \
        -notext \
        -batch

    touch intermediate-ca/intermediate_ca.crl

    echo -e "${GREEN}Verifying client_revoked certificate${NC}"
    openssl x509 \
        -in chain/client_revoked.pem.crt \
        -subject \
        -noout
    openssl verify \
      -CAfile chain/ca_bundle.pem.crt \
      chain/client_revoked.pem.crt

      #-crl_check \
      #-CRLfile intermediate-ca/intermediate_ca.crl \

    cat \
      "${SCRIPT_DIR}"/chain/client_revoked.pem.crt \
      "${SCRIPT_DIR}"/intermediate-ca/intermediate_ca.pem.crt \
      > "${SCRIPT_DIR}"/chain/client_revoked_bundle.pem.crt

    echo -e "${GREEN}Revoking client_revoked certificate${NC}"
    openssl ca \
      -revoke chain/client_revoked.pem.crt \
      -config client_revoked.ssl.conf

    echo -e "${GREEN}Creating CRL${NC}"
    openssl ca \
      -gencrl \
      -out intermediate-ca/intermediate_ca.crl \
      -config client_revoked.ssl.conf

    openssl verify \
      -CAfile chain/ca_bundle.pem.crt \
      -crl_check \
      -CRLfile intermediate-ca/intermediate_ca.crl \
      chain/client_revoked.pem.crt \
      || echo -e "${GREEN}client_revoked failed revocation check as expected${NC}"
}

create_oscp_responder1_certs() {
    # Creating the certificate for our client
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo -e "${GREEN}Creating OCSP responder1 private key${NC}"
    openssl genrsa \
        -out chain/ocsp_responder1.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your
    # organisation, which you can make up or just accept the defaults:
    echo -e "${GREEN}Creating OCSP responder1 certificate signing request${NC}"
    openssl req \
        -new \
        -key chain/ocsp_responder1.unencrypted.key \
        -out chain/ocsp_responder1.csr \
        -batch \
        -config ocsp_responder1.ssl.conf

    # Which we can sign using the CA, to get our client certificate: 
    echo -e "${GREEN}Creating OCSP responder1 certificate${NC}"
    openssl x509 \
        -extfile ocsp_responder1.ssl.conf \
        -extensions x509_ext \
        -req \
        -in chain/ocsp_responder1.csr \
        -CAkey certificate-authority/ca.unencrypted.key \
        -CA certificate-authority/ca.pem.crt \
        -out chain/ocsp_responder1.pem.crt \
        -days "${DAYS_TO_EXPIRY}" \
        -sha512

    echo -e "${GREEN}Verifying OCSP responder1 certificate${NC}"
    openssl x509 \
        -in chain/ocsp_responder1.pem.crt \
        -issuer \
        -subject \
        -noout

    openssl verify \
      -CAfile chain/ca_bundle.pem.crt \
      chain/ocsp_responder1.pem.crt
}

create_oscp_responder2_certs() {
    # Creating the certificate for our client
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # We create the key:
    echo -e "${GREEN}Creating OCSP responder2 private key${NC}"
    openssl genrsa \
        -out chain/ocsp_responder2.unencrypted.key \
        2048

    # Then we create a signing request. This asks for information about your
    # organisation, which you can make up or just accept the defaults:
    echo -e "${GREEN}Creating OCSP responder2 certificate signing request${NC}"
    openssl req \
        -new \
        -key chain/ocsp_responder2.unencrypted.key \
        -out chain/ocsp_responder2.csr \
        -batch \
        -config ocsp_responder2.ssl.conf

    # Which we can sign using the CA, to get our client certificate: 
    echo -e "${GREEN}Creating OCSP responder2 certificate${NC}"
    openssl x509 \
        -extfile ocsp_responder2.ssl.conf \
        -extensions x509_ext \
        -req \
        -in chain/ocsp_responder2.csr \
        -CAkey intermediate-ca/intermediate_ca.unencrypted.key \
        -CA intermediate-ca/intermediate_ca.pem.crt \
        -out chain/ocsp_responder2.pem.crt \
        -days "${DAYS_TO_EXPIRY}" \
        -sha512

    echo -e "${GREEN}Verifying OCSP responder2 certificate${NC}"
    openssl x509 \
        -in chain/ocsp_responder2.pem.crt \
        -issuer \
        -subject \
        -noout

    openssl verify \
      -CAfile chain/ca_bundle.pem.crt \
      chain/ocsp_responder2.pem.crt
}

delete_existing_certs() {
    echo -e "${GREEN}Deleting existing files${NC}"
    rm -f "${SCRIPT_DIR}"/certificate-authority/*.*
    rm -f "${SCRIPT_DIR}"/intermediate-ca/*.*
    rm -f "${SCRIPT_DIR}"/chain/*.*
    rm -f "${SCRIPT_DIR}"/client/*.*
    rm -f "${SCRIPT_DIR}"/server/*.*
}

main() {

    check_for_installed_binaries

    #Get the dir that this script lives in, no matter where it is called from
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    DAYS_TO_EXPIRY=5000

    delete_existing_certs

    mkdir -p "${SCRIPT_DIR}"/chain/
    mkdir -p "${SCRIPT_DIR}"/client/
    mkdir -p "${SCRIPT_DIR}"/server/

    mkdir -p "${SCRIPT_DIR}"/certificate-authority/newcerts/
    touch "${SCRIPT_DIR}"/certificate-authority/index.txt
    echo "01" > "${SCRIPT_DIR}"/certificate-authority/serial
    echo "01" > "${SCRIPT_DIR}"/certificate-authority/crl_number

    mkdir -p "${SCRIPT_DIR}"/intermediate-ca/newcerts/
    touch "${SCRIPT_DIR}"/intermediate-ca/index.txt
    echo "01" > "${SCRIPT_DIR}"/intermediate-ca/serial
    echo "01" > "${SCRIPT_DIR}"/intermediate-ca/crl_number

    create_ca_certs
    create_intermediate_ca_certs
    copy_ca_certs
    create_server_certs
    create_client1_certs
    create_client2_certs
    create_client_revoked_certs
    create_oscp_responder1_certs
    create_oscp_responder2_certs

    echo -e "${GREEN}Done!${NC}"
}

# Run an OCSP server for root CA
# openssl ocsp -index certificate-authority/index.txt -port 8070 -rsigner chain/ocsp_responder1.pem.crt -rkey chain/ocsp_responder1.unencrypted.key -CA chain/ca_bundle.pem.crt -text
# Run an OCSP server for intermediate CA
# openssl ocsp -index intermediate-ca/index.txt -port 8072 -rsigner chain/ocsp_responder2.pem.crt -rkey chain/ocsp_responder2.unencrypted.key -CA chain/ca_bundle.pem.crt -text

# How to perform an OCSP check
# openssl ocsp -issuer intermediate-ca/intermediate_ca.pem.crt -cert chain/client2.pem.crt -CAfile chain/ca_bundle.pem.crt -url http://localhost:8070/ -resp_text

main "$@"
