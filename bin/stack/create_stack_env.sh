#!/usr/bin/env bash
#
# Takes docker-compose yaml and extracts the possible configurations, 
# including the default values. This can be used to make sure the 
# configuration is always complete.

set -e

source lib/shell_utils.sh
source lib/network_utils.sh

create_config() {
    rm -f "${OUTPUT_FILE}"
    touch "${OUTPUT_FILE}"
    chmod +x "${OUTPUT_FILE}"
}

add_params() {
    local -r CONTAINER_VERSIONS_FILE="container_versions.env"

    # Scan the yml file to extract the default value to build an env file
    params=$( \
        # Bit of a fudge to ignore the echo lines in stroomAllDbs.yml
        grep -v "\w* echo" "${INPUT_FILE}" |
        # Extracts the params
        grep -Po "(?<=\\$\\{).*?(?=\\})" |
        # Replaces ':-' with '='
        sed "s/:-/=\"/g" |
        # Adds a closing double quote to the end of the line
        sed "s/$/\"/g" |
        # Adds 'export' to the start of the line
        sed "s/^/export /" | 
        # Add in the stack name
        sed "s/<STACK_NAME>/${BUILD_STACK_NAME}/g" )

    echo "${params}" >> "${OUTPUT_FILE}"

    # OUTPUT_FILE contains stuff like STROOM_TAG=v6.0-LATEST, i.e. development
    # docker tags, so we need to replace them with fixed versions from 
    # CONTAINER_VERSIONS_FILE. 

    echo -e "${GREEN}Setting container versions${NC}"
    # Sub shell so we don't pollute ours
    (
        # read all the exports
        source ${CONTAINER_VERSIONS_FILE}

        grep -E "^\s*export.*" ${CONTAINER_VERSIONS_FILE} | while read line; do
            local var_name
            local version
            var_name="$(echo "${line}" | sed -E 's/^.*export\s+([A-Z_]+)=.*/\1/')"
            version="$(echo "${line}" | sed -E 's/^.*export\s+[A-Z_]+=(.*)/\1/')"

            # Support lines like:
            # export STROOM_PROXY_TAG="${STROOM_TAG}"
            if [[ "${version}" =~ .*\$\{.*\}.* ]]; then
                # Use bash indirect expansion ('!') to read the value of a variable with a given name
                expanded_version="${!var_name}"
                echo -e "  Expanding ${BLUE}${var_name}${NC} from ${BLUE}${version}${NC} to ${BLUE}${expanded_version}${NC}"
                version="${expanded_version}"
            fi

            # check if file contains the var or interest
            if grep -E --silent "\s*${var_name}=" "${OUTPUT_FILE}"; then
                echo -e "  Changing ${BLUE}${var_name}${NC} to ${BLUE}${version}${NC}"
                # repalce var in OUTPUT_FILE with our CONTAINER_VERSIONS_FILE one
                sed -i'' -E "s#^export\s+${var_name}=.*#export ${var_name}=${version}#g" "${OUTPUT_FILE}"
            fi
        done
    )

    # If there is a <stack_name>.override.env file in ./overrides then replace any matching env
    # vars found in the OUTPUT_FILE with the values from the override file.
    # This allows a stack to differ slightly from the defaults taken from the yml
    if [ -f "${OVERRIDE_FILE}" ]; then
        echo -e "${GREEN}Applying variable overrides${NC}"

        grep -o "^\s*[A-Z_]*=.*" "${OVERRIDE_FILE}" | while read line; do
            # Extract the var name and value from the override file line
            local var_name="${line%%=*}"
            local override_value="${line#*=}"

            local curr_line
            local curr_value
            #echo "line [${line}], var_name [${var_name}], override_value [${override_value}]"

            # Extract the existing variable value from the env file
            # TODO - it is possible that there may be more that one use of the same
            # variable so we just have to take the first one and assume they have the same
            # default values.
            curr_line="$(grep -E "${var_name}=.*$" "${OUTPUT_FILE}" | head -n1)"
            curr_value="${curr_line#*=}"

            #echo "curr_line [${curr_line}], curr_value [${curr_value}]"

            echo
            echo -e "  Overriding ${DGREY}${var_name}=${curr_value}${NC}"
            echo -e "  With       ${YELLOW}${var_name}${NC}=${BLUE}${override_value}${NC}"

            # Replace the current value with the override
            # This line may break if the sed delimiter (currently |) appears in ${override_value}
            sed -i'' -E "s|(${var_name})=.*|\1=${override_value}|g" "${OUTPUT_FILE}"
        done
    fi
}

create_versions_file() {

    # Produce a list of fully qualified docker image tags by sourcing the OUTPUT_FILE
    # that contains all the env vars and using their values to do variable substitution
    # against the image definitions obtained from the yml (INPUT_FILE)
    # Source the env file in a subshell to avoid poluting ours
    ( 
        source "${OUTPUT_FILE}"
        
        # Find all image: lines in the yml and turn them into echo statements so we can
        # eval them so bash does its variable substitution. Bit hacky using eval.
        grep "image:" "${INPUT_FILE}" | 
            sed -e 's/\s*image:\s*/echo /g' | 
            while read line; do
                eval "${line}"
            done 
    ) | sort | uniq > "${VERSIONS_FILE}"

    echo -e "${GREEN}Using container versions:${NC}"

    while read line; do
        echo -e "  ${BLUE}${line}${NC}"
    done < "${VERSIONS_FILE}" 


    # TODO validate tags
    #if docker_tag_exists library/nginx 1.7.5; then
        #echo exist
    #else 
        #echo not exists
    #fi
}

main() {
    setup_echo_colours

    echo -e "${GREEN}Creating configuration${NC}"

    local -r BUILD_STACK_NAME=$1
    local -r VERSION=$2
    local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
    local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}/config"
    mkdir -p "${WORKING_DIRECTORY}"
    local -r INPUT_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.yml"
    local -r OUTPUT_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.env"
    local -r OVERRIDE_FILE="overrides/${BUILD_STACK_NAME}.override.env"
    local -r VERSIONS_FILE="${WORKING_DIRECTORY}/../VERSIONS.txt"

    create_config
    add_params

    # Sort and de-duplicate param list before we do anything else with the file
    sort -o "${OUTPUT_FILE}" -u "${OUTPUT_FILE}"
    create_versions_file
}

main "$@"
