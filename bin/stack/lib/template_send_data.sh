#!/usr/bin/env bash
#
# Sends data to stroom or stroom-proxy

set -e

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR:-.}"/lib/shell_utils.sh

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

readonly VALID_DESTINATIONS="stroom|stroom-proxy"

main() {

    local -r data_dir="$1"
    local -r destination="$2"
    local -r feed_name="$3"
    local -r system_name="$4"
    local -r environment="$5"
    
    #echo -e "${GREEN}Sending data in ${BLUE}${data_dir}${GREEN} to ${BLUE}${destination}${GREEN}" \
        #" with feed: ${BLUE}${feed_name}${GREEN}" \
        #", system: ${BLUE}${system_name}${GREEN}" \
        #" and environment: ${BLUE}${environment}${NC}"

    if [ "${destination}" = "stroom" ]; then
        local port=443
    elif [ "${destination}" = "stroom-proxy" ]; then
        local port=${STROOM_PROXY_HTTPS_APP_PORT}
    else
        die "${RED}ERROR:${GREEN} invalid destination ${BLUE}${destination}${NC}, should be one of (${BLUE}${VALID_DESTINATIONS}${NC}${GREEN})${NC}"
    fi

    local url=https://localhost:${port}/stroom/datafeed

    if [ ! -d "${data_dir}" ]; then
        die "${RED}ERROR:${GREEN} data directory ${BLUE}${data_dir}${GREEN} does not exist${NC}"
    fi

     "${DIR:-.}"/lib/send_to_stroom.sh \
        --no-secure \
        --pretty \
        --file-regex ".*/.*" \
        --key ./certs/client.unencrypted.key \
        --cert ./certs/client.pem.crt \
        --cacert ./certs/ca.pem.crt \
        "${data_dir}" \
        "${feed_name}" \
        "${system_name}" \
        "${environment}" \
        "${url}"
}

# ~~~ Script starts here ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

setup_echo_colours

required_arg_count=5
if [ $# -ne ${required_arg_count} ]; then
    echo -e "${RED}ERROR:${GREEN} Invalid arguments, found $# args, required ${required_arg_count}${NC}" >&2
    echo -e "${GREEN}Usage: ${BLUE}$0 data-directory destination(${VALID_DESTINATIONS}) feed-name system-name environment${NC}" >&2
    echo -e "${GREEN}E.g.:  ${BLUE}$0 /tmp/data stroom-proxy TEST_FEED MY_TEST_SYSTEM DEV${NC}" >&2
    echo -e "This script will send all files contained in data-directory to the destination system."
    echo -e "All files successfully sent will be deleted. It does not recurse into child directories."
    exit 1
fi

main "$@"

