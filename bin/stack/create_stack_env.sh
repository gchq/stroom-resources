#!/usr/bin/env bash
#
# Takes docker-compose yaml and extracts the possible configurations, 
# including the default values. This can be used to make sure the 
# configuration is always complete.

source lib/shell_utils.sh
source lib/network_utils.sh

create_config() {
    rm -f "${OUTPUT_FILE}"
    touch "${OUTPUT_FILE}"
    chmod +x "${OUTPUT_FILE}"
}

add_params() {
    readonly CONTAINER_VERSIONS_FILE="container_versions.env"

    params=$( \
        # Extracts the params
        grep -Po "(?<=\\$\\{).*?(?=\\})" ${INPUT_FILE} |
        # Replaces ':-' with '='
        sed "s/:-/=\"/g" |
        # Adds a closing single quote to the end of the line
        sed "s/$/\"/g" |
        # Adds 'export' to the start of the line
        sed "s/^/export /" | 
        # Add in the stack name
        sed "s/<STACK_NAME>/${STACK_NAME}/g" )

    echo "${params}" >> "${OUTPUT_FILE}"

    # OUTPUT_FILE contains stuff like STROOM_TAG=v6.0-LATEST, i.e. development
    # docker tags, so we need to replace them with fixed versions from 
    # CONTAINER_VERSIONS_FILE. The sed command below finds all _TAG entries
    # in OUTPUT_FILE and replaces them with the output of grepping the
    # CONTAINER_VERSIONS_FILE for that _TAG entry. The 'e' flag executes the 
    # result of the repalcement.

    # NOTE if this cmd fails it is probably because you don't have GNU sed. 
    sed -i'' -E "s/(export .*_TAG).*/grep \"\1\" ${CONTAINER_VERSIONS_FILE}/e" ${OUTPUT_FILE}
}

main() {
    setup_echo_colours

    echo -e "${GREEN}Creating configuration${NC}"

    local -r STACK_NAME=$1
    local -r BUILD_FOLDER='build'
    local -r WORKING_DIRECTORY="${BUILD_FOLDER}/${STACK_NAME}/config"
    mkdir -p ${WORKING_DIRECTORY}
    local -r INPUT_FILE="${WORKING_DIRECTORY}/${STACK_NAME}.yml"
    local -r OUTPUT_FILE="${WORKING_DIRECTORY}/${STACK_NAME}.env"

    create_config
    add_params
    # Sort and de-duplicate param list before we do anything else with the file
    sort -o "${OUTPUT_FILE}" -u "${OUTPUT_FILE}"
}

main "$@"
