#!/bin/bash

######################################################################################
# 
# Script to fetch a list of the most recent releases from stroom-resources/releases,
# select one of the tags, download ther associated stack asset and deploy it.
#
######################################################################################

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
    command -v fzf 1>/dev/null || error_exit "${GREEN}${binary_name}${RED} is not installed"
}

check_for_installed_binaries() {
    check_for_installed_binary "fzf"
    check_for_installed_binary "http"
    check_for_installed_binary "jq"
    check_for_installed_binary "wget"
}

main(){

    [ $# -eq 1 ] || error_exit "${RED}Invalid arguments. ${BLUE}Usage: getStack.sh /new/path/to/create/stack/in${NC}"

    check_for_installed_binaries

    install_dir="$1"

    [ ! -d ${install_dir} ] || error_exit "${RED}Directory ${GREEN}${install_dir}${RED} already exists"

    mkdir -p "${install_dir}"

    cd "${install_dir}"

    # Use fzf to get a release tag name
    local tag=$( \
        http https://api.github.com/repos/gchq/stroom-resources/releases | 
        jq -r "[.[]][].tag_name" | 
        sort |
        fzf)

    [ $? -eq 0 ] || error_exit "Something went wrong looking up the tag"

    local url=$( \
        http https://api.github.com/repos/gchq/stroom-resources/releases/tags/${tag} | 
        jq -r '.assets[0].browser_download_url')

    local file=$( \
        http https://api.github.com/repos/gchq/stroom-resources/releases/tags/${tag} | 
        jq -r '.assets[0].name')

    [ $? -eq 0 ] || error_exit "Something went wrong getting the asset url"


    [[ ${url} =~ .*\.tar\.gz$ ]] || error_exit "${RED}Download assest does not match expected pattern${NC}"
    #local -r url="https://github.com/gchq/stroom-resources/releases/download/${tag}/${tag}.tar.gz"
    
    echo -e "${GREEN}Downloading file ${BLUE}${file}${NC}"
    echo -e "${GREEN}From ${BLUE}${url}${NC}"
    echo -e "${GREEN}Deploying to ${BLUE}${install_dir}${NC}"

    wget -q ${url}

    #local file="${tag}.tar.gz" 

    [ -f ${file} ] || error_exit "${RED}File ${GREEN}${file}${RED} doesn't exist, it should as we just downloaded it${NC}"

    tar -xvf ${file}

    echo -e "${GREEN}Deleting downloaded file ${BLUE}${file}${NC}"
    rm ${file}

    echo
    echo -e "${GREEN}Stroom stack ${BLUE}${tag} ${GREEN}is now available at ${BLUE}${install_dir}${NC}"
    echo
}

main $@
