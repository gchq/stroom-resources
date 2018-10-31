#!/usr/bin/env bash
#
# Displays info about the stack

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/network_utils.sh
source "$DIR"/lib/shell_utils.sh

readonly HOST_IP=$(determine_host_address)

setup_echo_colours

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

echo_info_line() {
    # Echos a line like "  PADDED_STRING                    UNPADDED_STRING"

    local -r padding=$1
    local -r padded_string=$2
    local -r unpadded_string=$3
    # Uses bash substitution to only print the part of padding beyond the length of padded_string
    printf "  ${GREEN}%s${NC} %s${BLUE}${unpadded_string}${NC}\n" "${padded_string}" "${padding:${#padded_string}}"
}

main() {
    # see if the terminal supports colors...
    no_of_colours=$(tput colors)

    if test -n "$no_of_colours" && test $no_of_colours -eq 256; then
        # 256 colours so print the stroom banner in dirty orange
        echo -en "\e[38;5;202m"
    else
        # No 256 colour support so fall back to blue
        echo -en "${BLUE}"
    fi
    cat ${DIR}/lib/banner.txt
    echo -en "${NC}"

    echo
    echo -e "Stack image versions:"
    echo

    # Used for right padding 
    local -r padding="                            "

    while read line; do
        local image_name="$(echo $line | cut -d ':' -f 1)"
        local image_version="$(echo $line | cut -d ':' -f 2)"
        echo_info_line "${padding}" "${image_name}" "${image_version}"
    done < ${DIR}/VERSIONS.txt

    echo
    echo -e "The following admin pages are available"
    echo
    echo_info_line "${padding}" "Stroom" "http://localhost:${STROOM_ADMIN_PORT}/stroomAdmin"

    if [[ ! -z ${STROOM_STATS_SERVICE_ADMIN_PORT} ]]; then
        echo_info_line "${padding}" "Stroom Stats" "http://localhost:${STROOM_STATS_SERVICE_ADMIN_PORT}/statsAdmin"
    fi

    echo_info_line "${padding}" "Stroom Proxy" "http://localhost:${STROOM_PROXY_ADMIN_PORT}/proxyAdmin"
    echo_info_line "${padding}" "Stroom Auth" "http://localhost:${STROOM_AUTH_SERVICE_ADMIN_PORT}/authenticationServiceAdmin"

    echo
    echo -e "Data can be POSTed to Stroom using the following URLs (see README for details)"
    echo
    echo_info_line "${padding}" "Stroom Proxy" "https://localhost:${STROOM_PROXY_HTTPS_APP_PORT}/stroom/datafeed"
    echo_info_line "${padding}" "Stroom (direct)" "https://localhost/stroom/datafeed"

    echo
    echo -e "The Stroom user interface can be accessed at the following URL"
    echo
    echo_info_line "${padding}" "Stroom UI" "http://localhost/stroom"
    echo
    echo -e "  (Login with the default username/password: ${BLUE}admin${NC}/${BLUE}admin${NC})"
    echo
}


main "$@"
