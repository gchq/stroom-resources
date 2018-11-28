#!/usr/bin/env bash
#
# Use this script to load a SQL database dump into a temporary database.
# This is useful for testing database migrations.

set -e

source lib/shell_utils.sh

validate_requested_services() {
    # TODO: Rename the yaml to reflect the container names, i.e. from camel case to dashed.
    local -r VALID_SERVICES='stroom stroomAllDbs zookeeper stroomStats stroomQueryElasticUi stroomQueryElasticService stroomProxyLocal stroomAuthUi stroomAuthService stroomAnnotationsUi stroomAnnotationsService stroomLogSender nginx kibana kafka hbase fakeSmtp elasticsearch hdfs'

    for service in "${@}"; do
        if [[ ${VALID_SERVICES} != *${service}* ]]; then
            services_are_valid=false
            err "${RED}'${service}'${NC} is not a valid service!"
            exit 1
        fi
    done
}

create_stack_from_services() {
    local -r PATH_TO_CONTAINERS="../compose/containers"
    echo version: \'2.4\'
    echo services:
    for service in "$@"; do
        local target_yaml="${PATH_TO_CONTAINERS}/${service}.yml"
        # TODO: make this a single grep
        local service
        service=$(grep -v '^services' "${target_yaml}" | grep -v '^version:')
        echo "${service}"
    done
}

append_shared_volumes() {
    local -r MASTER_YAML="../compose/everything.yml"

    # grab all content from master yaml file after and including 'volumes:' entry
    # and ignoring comments
    sed -n -e '/^\w*volumes:/,$p' "${MASTER_YAML}" \
        | grep -v '^\w*#' >> "${OUTPUT_FILE}"
}

main() {
    setup_echo_colours

    local -r BUILD_STACK_NAME=$1
    local -r VERSION=$2
    local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
    local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}/config"

    mkdir -p $WORKING_DIRECTORY
    local -r OUTPUT_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.yml"
    validate_requested_services "${@:3}"

    if [ -z ${services_are_valid+x} ]; then
        echo -e "${GREEN}Creating a stack called ${YELLOW}${BUILD_STACK_NAME}${GREEN} with version ${YELLOW}${VERSION}${GREEN} and the following services:${NC}"
        for service in "${@:3}"; do
            echo -e "  ${BLUE}${service}${NC}"
        done
        create_stack_from_services "${@:3}" > "${OUTPUT_FILE}"
        append_shared_volumes
    else
        err "Please choose from the following services and try again: ${GREEN}${VALID_SERVICES}${NC}"
        exit 1
    fi
}

main "$@"
