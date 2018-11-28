#!/usr/bin/env bash
#
# Stops the stack

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh
setup_echo_colours

stop_service_if_in_stack() {
    local -r service_name="$1"

    echo -e "${GREEN}Stopping container ${BLUE}${service_name}${NC}"

    local -r state="$(docker inspect -f '{{.State.Running}}' ${service_name})"

    if [ "${state}" = "true" ]; then
        docker-compose --project-name <STACK_NAME> -f "$DIR"/config/<STACK_NAME>.yml stop "${service_name}"
    else
        echo -e "  Container ${BLUE}${service_name}${NC} is not running"
    fi

}

main() {

    echo -e "${GREEN}Stopping the docker containers in graceful order${NC}"
    echo

    # Order is critical here for a graceful shutdown
    stop_service_if_in_stack "stroom-log-sender"
    stop_service_if_in_stack "stroom-proxy-local"
    stop_service_if_in_stack "nginx"
    stop_service_if_in_stack "stroom-auth-ui"
    stop_service_if_in_stack "stroom-auth-service"
    stop_service_if_in_stack "stroom"
    stop_service_if_in_stack "stroom-all-dbs"

    # In case we have missed any stop the whole project
    echo -e "${GREEN}Stopping any remaining containers in the stack${NC}"
    docker-compose --project-name <STACK_NAME> -f "$DIR"/config/<STACK_NAME>.yml stop

    echo
    echo -e "${GREEN}Done${NC}"
}

main
