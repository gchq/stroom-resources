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

setup_echo_colours

readonly HOST_IP=$(determine_host_address)

source "$DIR"/config/<STACK_NAME>.env

echo -e "${GREEN}Restarting the docker containers${NC}"
echo

docker-compose --project-name <STACK_NAME> -f "$DIR"/config/<STACK_NAME>.yml restart

echo
echo -e "${GREEN}Waiting for stroom to complete its restart.${NC}"

wait_for_200_response "http://localhost:${STROOM_ADMIN_PORT}/stroomAdmin"

echo
echo -e "${GREEN}Ready${NC}"
