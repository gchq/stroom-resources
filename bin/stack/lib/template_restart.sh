#!/usr/bin/env bash
#
# shellcheck disable=SC2034
# shellcheck disable=SC1090
#
# Restarts the stack

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/network_utils.sh
source "$DIR"/lib/shell_utils.sh
source "$DIR"/lib/stroom_utils.sh

setup_echo_colours

# This is needed in the docker compose yaml
readonly HOST_IP=$(determine_host_address)

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

main() {

    stop_stack "<STACK_NAME>" 

    echo

    start_stack "<STACK_NAME>"

    echo
    echo -e "${GREEN}Waiting for stroom to complete its start up.${NC}"

    wait_for_200_response "http://localhost:${STROOM_ADMIN_PORT}/stroomAdmin"

    # Stroom is now up or we have given up waiting so check the health
    check_overall_health

    # Display the banner, URLs and login details
    display_stack_info
}

main
