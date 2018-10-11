#!/usr/bin/env bash
#
# Use this script to load a SQL database dump into a temporary database.
# This is useful for testing database migrations.

source lib/shell_utils.sh

validate_requested_services() {
    # TODO: Rename the yaml to reflect the container names, i.e. from camel case to dashed.
    local -r VALID_SERVICES='stroom stroomAllDbs zookeeper stroomStats stroomQueryElasticUi stroomQueryElasticService stroomProxy stroomAuthUi stroomAuthService stroomAnnotationsUi stroomAnnotationsService nginx kibana kafka hbase fakeSmtp elasticsearch hdfs'

    for service in "${@:2}"; do
        if [[ $VALID_SERVICES != *$service* ]]; then
            services_are_valid=false
            err "${RED}'$service'${NC} is not a valid service!"
            exit 1
        fi
    done
}

create_stack_from_services() {
    local -r PATH_TO_CONTAINERS="../compose/containers"
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

    local -r BUILD_FOLDER='build'
    local -r STACK_NAME=$1
    local -r WORKING_DIRECTORY="$BUILD_FOLDER/$STACK_NAME/config"
    mkdir -p $WORKING_DIRECTORY
    local -r OUTPUT_FILE="$WORKING_DIRECTORY/$STACK_NAME.yml"
    mkdir -p $WORKING_DIRECTORY
    validate_requested_services "${@}"

    if [ -z ${services_are_valid+x} ]; then
        echo -e "${GREEN}Creating a stack called ${YELLOW}${STACK_NAME}${GREEN} with the following services:"
        for service in "${@:2}"; do
            echo -e "  ${BLUE}${service}${NC}"
        done
        create_stack_from_services "${@:2}" > "$OUTPUT_FILE"
    else
        err "Please choose from the following services and try again: ${GREEN}$VALID_SERVICES${NC}"
        exit 1
    fi
}

main "$@"
