#!/usr/bin/env bash
#
# Use this script to load a SQL database dump into a temporary database.
# This is useful for testing database migrations.

create_stack_from_services() {
    echo version: '2.1'
    echo services:
    for service in "$@"; do
        local target_yaml="compose/containers/$service.yml"
        # TODO: make this a single grep
        local service
        service=$(grep -v '^services' "$target_yaml" | grep -v '^version:')
        echo "$service"
    done
}

main(){
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

    readonly local OUTPUT_FILE=$1
    readonly local VALID_SERVICES='stroom stroomDb'
    for service in "${@:2}"; do
        if [[ $VALID_SERVICES != *$service* ]]; then
            services_are_valid=false
            echo -e "${RED}'$service'${NC} is not a valid service!"
        fi
    done

    if [ -z ${services_are_valid+x} ]; then
        echo -e "Creating a stack with the following services: ${GREEN}${@:2}${NC}"
        echo -e "Saving to file ${GREEN}$1${NC}"
        create_stack_from_services "${@:2}" > $OUTPUT_FILE
    else
        echo -e "Please choose from the following services and try again: ${GREEN}$VALID_SERVICES${NC}"
    fi
}

main "$@"