#!/usr/bin/env bash
#
# Use this script to load a SQL database dump into a temporary database.
# This is useful for testing database migrations.

source common.sh

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

validate_requested_services() {
    # TODO: Rename the yaml to reflect the container names, i.e. from camel case to dashed.
    readonly local VALID_SERVICES='stroom stroomDb zookeeper stroomStatsDb stroomStats stroomQueryElasticUi stroomQueryElasticService stroomProxy stroomAuthUi stroomAuthService stroomAuthDb stroomAnnotationsUi stroomAnnotationsService stroomAnnotationsDb nginx kibana kafka hbase fakeSmtp elasticsearch'

    for service in "${@:2}"; do
        if [[ $VALID_SERVICES != *$service* ]]; then
            services_are_valid=false
            echo -e "${RED}'$service'${NC} is not a valid service!"
        fi
    done
}

main() {
    setup_echo_colours

    readonly local OUTPUT_FILE=$1
    validate_requested_services "${@}"

    if [ -z ${services_are_valid+x} ]; then
        echo -e "Creating a stack with the following services: ${GREEN}${*:2}${NC}"
        echo -e "Saving to file ${GREEN}$1${NC}"
        create_stack_from_services "${@:2}" > "$OUTPUT_FILE"
    else
        echo -e "Please choose from the following services and try again: ${GREEN}$VALID_SERVICES${NC}"
    fi
}

main "$@"