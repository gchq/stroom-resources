#!/usr/bin/env bash

# Exit the script on any error
set -e

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
LGREY='\e[37m'
DGREY='\e[90m'
NC='\033[0m' # No Color

main() {
    # <STACK_VERSION> will be replaced by travis at build time
    local -r stack_version="<STACK_VERSION>"
    local -r install_dir="./${stack_version}"
    local -r url="https://github.com/gchq/stroom-resources/releases/download/${stack_version}/${stack_version}.tar.gz"

    if [ -d "${install_dir}" ]; then
        echo -e "${RED}ERROR${NC}: Directory ${BLUE}${install_dir}${NC} already exists!${NC}"
        exit 1
    fi

    echo -e "${GREEN}This script will create directory ${BLUE}${install_dir}${GREEN} and download${NC}"
    echo -e "${GREEN}Stroom stack ${BLUE}${stack_version}${GREEN} into it.${NC}"

    echo
    read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

    if [ "${keyPressed}" = 'y' ] || [ "${keyPressed}" = 'Y' ]; then
        echo
    else
        echo
        echo "Exiting"
        exit 0
    fi

    echo
    echo -e "${GREEN}Creating directory ${BLUE}${install_dir}${NC}"

    mkdir -p "${stack_version}"

    echo
    echo -e "${GREEN}Downloading and unpacking stack ${BLUE}${url}${NC}"

    curl -sL "${url}" \
        | tar xz -C "${install_dir}"

    echo
    echo -e "${GREEN}Start Stroom using ${BLUE}start.sh${GREEN} in ${BLUE}${install_dir}${NC}"
    echo -e "${GREEN}or read the ${BLUE}README.md${GREEN} file.${NC}"
    echo
}

main 
