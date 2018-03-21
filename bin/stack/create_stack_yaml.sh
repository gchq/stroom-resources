#!/usr/bin/env bash
#
# Use this script to load a SQL database dump into a temporary database.
# This is useful for testing database migrations.

source lib/shell_utils.sh

validate_requested_services() {
    # TODO: Rename the yaml to reflect the container names, i.e. from camel case to dashed.
    readonly local VALID_SERVICES='stroom stroomDb zookeeper stroomStatsDb stroomStats stroomQueryElasticUi stroomQueryElasticService stroomProxy stroomAuthUi stroomAuthService stroomAuthDb stroomAnnotationsUi stroomAnnotationsService stroomAnnotationsDb nginx kibana kafka hbase fakeSmtp elasticsearch ctop'

    for service in "${@:2}"; do
        if [[ $VALID_SERVICES != *$service* ]]; then
            services_are_valid=false
            err "${RED}'$service'${NC} is not a valid service!"
            exit 1
        fi
    done
}

create_stack_from_services() {
    readonly local PATH_TO_CONTAINERS="../compose/containers"
    echo version: \'2.1\'
    echo services:
    for service in "$@"; do
        local target_yaml="$PATH_TO_CONTAINERS/$service.yml"
        # TODO: make this a single grep
        local service
        service=$(grep -v '^services' "$target_yaml" | grep -v '^version:')
        echo "$service"
    done
}

main() {
    setup_echo_colours

    readonly local BUILD_FOLDER='build'
    readonly local STACK_NAME=$1
    readonly local WORKING_DIRECTORY="$BUILD_FOLDER/$STACK_NAME/config"
    mkdir -p $WORKING_DIRECTORY
    readonly local OUTPUT_FILE="$WORKING_DIRECTORY/$STACK_NAME.yml"
    mkdir -p $WORKING_DIRECTORY
    validate_requested_services "${@}"

    if [ -z ${services_are_valid+x} ]; then
        echo -e "${GREEN}Creating a stack called ${YELLOW}$STACK_NAME${GREEN} with the following services: ${BLUE}${*:2}${NC}"
        create_stack_from_services "${@:2}" > "$OUTPUT_FILE"
    else
        err "Please choose from the following services and try again: ${GREEN}$VALID_SERVICES${NC}"
        exit 1
    fi
}

main "$@"