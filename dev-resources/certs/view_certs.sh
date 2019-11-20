#!/bin/bash

main() {
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

  echo
  echo -e "${GREEN}Verifying certificate authority certificate${NC}"
  openssl x509 \
    -in certificate-authority/ca.pem.crt \
    -text \
    -noout

  echo
  echo -e "${GREEN}Verifying server certificate${NC}"
  openssl x509 \
    -in server/server.pem.crt \
    -text \
    -noout

  echo
  echo -e "${GREEN}Verifying client certificate${NC}"
  openssl x509 \
    -in client/client.pem.crt \
    -text \
    -noout

}

main "$@"
