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

    # Scan the yml file to extract the default value to build an env file
    params=$( \
        # Bit of a fudge to ignore the echo lines in stroomAllDbs.yml
        grep -v "\w* echo" ${INPUT_FILE} |
        # Extracts the params
        grep -Po "(?<=\\$\\{).*?(?=\\})" |
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
    sed -i'' -E "s#(export .*_TAG).*#grep \"\1\" ${CONTAINER_VERSIONS_FILE}#e" ${OUTPUT_FILE}

    # If there is a <stack_name>.override.env file in ./overrides then replace any matching env
    # vars found in the OUTPUT_FILE with the values from the override file.
    # This allows a stack to differ slightly from the defaults taken from the yml
    if [ -f ${OVERRIDE_FILE} ]; then
        echo -e "${GREEN}Applying variable overrides${NC}"

        grep -o "[A-Z_]*=.*" ${OVERRIDE_FILE} | while read line; do
            # Extract the var name and value from the override file line
            local var_name="$(echo "${line}" | sed -E 's/([A-Z_]*)=.*/\1/')"
            local override_value="$(echo "${line}" | sed -E 's/[A-Z_]*=(.*)/\1/')"

            # Extract the existing variable value from the env file
            local curr_line="$(grep -E "${var_name}=.*" ${OUTPUT_FILE})"
            local curr_value="$(echo "${curr_line}" | sed -E "s/${var_name}=(.*)/\1/")"

            echo
            echo -e "  Overriding ${DGREY}${var_name}=${curr_value}${NC}"
            echo -e "  With       ${YELLOW}${var_name}${NC}=${BLUE}${override_value}${NC}"

            # Replace the current value with the override
            sed -i'' -E "s/(${var_name})=.*/\1=${override_value}/g" ${OUTPUT_FILE}
        done
    fi

    # Dump all the container tag variables to a file that will end up in the tar.gz
    cat ${OUTPUT_FILE} | 
        grep -E "export .*_TAG.*" > ${BUILD_FOLDER}/${STACK_NAME}/VERSIONS.txt

    echo -e "${GREEN}Using container versions:${NC}"
    cat ${BUILD_FOLDER}/${STACK_NAME}/VERSIONS.txt | sed 's/export //g' | while read line; do
        local var_name="$(echo "${line}" | sed -E 's/([A-Z_]*)=.*/\1/')"
        local value="$(echo "${line}" | sed -E 's/[A-Z_]*="(.*)"/\1/')"

        echo -e "  ${YELLOW}${var_name}${NC}: ${BLUE}${value}${NC}"
    done
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
    local -r OVERRIDE_FILE="overrides/${STACK_NAME}.override.env"

    create_config
    add_params
    # Sort and de-duplicate param list before we do anything else with the file
    sort -o "${OUTPUT_FILE}" -u "${OUTPUT_FILE}"
}

main "$@"
