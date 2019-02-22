#!/usr/bin/env bash
#
# Takes docker-compose yaml and extracts the possible configurations, 
# including the default values. This can be used to make sure the 
# configuration is always complete.

set -e

# shellcheck disable=SC1091
source lib/shell_utils.sh
# shellcheck disable=SC1091
source lib/network_utils.sh

create_config() {
  rm -f "${OUTPUT_FILE}"
  touch "${OUTPUT_FILE}"
  chmod +x "${OUTPUT_FILE}"
}

add_env_vars() {
  local -r CONTAINER_VERSIONS_FILE="container_versions.env"
  declare -A whitelisted_use_counters

  # Read the volume whitelist into an array
  local env_vars_whitelist=()
  if [ -f "${WHITELIST_FILE}" ]; then
    while read -r env_var_name; do
      if [[ ! "${env_var_name}" =~ ^[[:space:]]*(#.*)?$ ]]; then
        env_vars_whitelist+=("${env_var_name}")
        #echo "[${env_var_name}]"
        # Initialise the couter at zero for each whitelisted env var name
        # so we can track if any are not used
        whitelisted_use_counters[${env_var_name}]=0
      fi
    done < "${WHITELIST_FILE}"

    local use_whitelist=true
    echo -e "${GREEN}Adding white-listed environment variables to ${BLUE}${OUTPUT_FILE}${NC}"
    touch "${OUTPUT_FILE}"
  else
    echo -e "${RED}Warn${NC}: Environment variable whitelist file ${BLUE}${WHITELIST_FILE}${NC} not found."
    echo -e "${GREEN}Adding ALL environment variables to ${BLUE}${OUTPUT_FILE}${NC}"
    local use_whitelist=false
  fi

  # Scan the yml file to extract the default value to build an env file
  # In the yaml there are lines like:
  # - STROOM_JDBC_DRIVER_URL=jdbc:mysql://${STROOM_DB_HOST:-$HOST_IP}:${STROOM_DB_PORT:-3307}/stroom
  # and from lines like those we want to extract/transform to
  # STROOM_DB_HOST="$HOST_IP"
  # STROOM_DB_PORT="3307"
  all_env_vars=$( \
    # Bit of a fudge to ignore the echo lines in stroomAllDbs.yml
    grep -v "\w* echo" "${INPUT_FILE}" |
      # Extracts the params
      grep -Po "(?<=\\$\\{).*?(?=\\})" |
      # ignore commented lines
      grep -v '^\w*#' |
      # Replaces ':-' with '='
      sed "s/:-/=\"/g" |
      # Adds a closing double quote to the end of the line
      sed "s/$/\"/g" |
      # Add in the stack name
      sed "s/<STACK_NAME>/${BUILD_STACK_NAME}/g" )

  # associative array to hold counts of each env var seen
  declare -A usage_counters

  # Loop over all env vars found in the yaml
  while read -r env_var_name_value; do
    local var_name="${env_var_name_value%%=*}"
    local var_value="${env_var_name_value#*=}"

    # this bit of code keeps a count of the times we have seen each env
    # var, so we can warn about ones seen multiple times but not whitelisted
    if [[ -z "${usage_counters[${var_name}]}" ]]; then
      usage_counters[${var_name}]=1
    else
      # increment the counter
      (( usage_counters["${var_name}"]=usage_counters["${var_name}"] + 1 ))
    fi
    #echo "${var_name}: ${usage_counters[${var_name}]}"

    # If this env var is a whitelisted one then increment its count
    if [[ -n "${whitelisted_use_counters[${var_name}]}" ]]; then
      (( whitelisted_use_counters["${var_name}"]=whitelisted_use_counters["${var_name}"] + 1 ))
      #echo "Incrementing count for ${var_name}, new count ${whitelisted_use_counters["${var_name}"]}"
    fi

    # Now add the env var to the env file if we don't have a whitelist file
    # or it is white-listed
    if [ "${use_whitelist}" = "false" ] \
      || element_in "${var_name}" "${env_vars_whitelist[@]}"; then

      echo -e "  ${YELLOW}${var_name}${NC}=${BLUE}${var_value}${NC}"
      echo "export ${env_var_name_value}" >> "${OUTPUT_FILE}"
    fi
  done <<< "${all_env_vars}"

  # Error if any whitelisted env var is not used anywhere in the yaml
  echo -e "${GREEN}Checking for unused white-listed variables.${NC}"
  for var_name in "${!whitelisted_use_counters[@]}"; do
    #echo "count for ${var_name} = ${whitelisted_use_counters["${var_name}"]}"
    if [ "${whitelisted_use_counters[$var_name]}" -eq 0 ]; then
      die "${RED}  Error${NC}: White-listed environment variable ${YELLOW}${var_name}${NC} is not used in the yaml."
    fi
  done

  # Output warnings if an env var is used more than once in the yaml but is
  # not whitelisted.
  echo -e "${GREEN}Checking for environment variables used multiple times${NC}"
  for var_name in "${!usage_counters[@]}"; do
    #echo "count for ${var_name} = ${whitelisted_use_counters["${var_name}"]}"
    if [ "${usage_counters[$var_name]}" -gt 1 ] \
      && [[ -z "${whitelisted_use_counters[${var_name}]}" ]] ; then

      echo -e "${RED}  Warn${NC}: Environment variable ${YELLOW}${var_name}${NC} is used multiple times in the yaml but isn't white-listed. You may want to whitelist it."
    fi
  done

  # OUTPUT_FILE contains stuff like STROOM_TAG=v6.0-LATEST, i.e. development
  # docker tags, so we need to replace them with fixed versions from 
  # CONTAINER_VERSIONS_FILE. 

  echo -e "${GREEN}Setting container versions${NC}"
  # read all the exports
  # shellcheck disable=SC1091
  source ${CONTAINER_VERSIONS_FILE}

  # Implicit sub-shell doesn't matter as we are not modifying any outer variables
  grep -E "^\s*export.*" ${CONTAINER_VERSIONS_FILE} | while read -r line; do
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

  # If there is a <stack_name>.override.env file in ./overrides then replace any matching env
  # vars found in the OUTPUT_FILE with the values from the override file.
  # This allows a stack to differ slightly from the defaults taken from the yml
  if [ -f "${OVERRIDE_FILE}" ]; then
    echo -e "${GREEN}Applying variable overrides${NC}"

    grep -o "^\s*[A-Z_]*=.*" "${OVERRIDE_FILE}" | while read -r line; do
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
  # shellcheck disable=SC1090
  ( 
    source "${OUTPUT_FILE}"

    # Find all image: lines in the yml and turn them into echo statements so we can
    # eval them so bash does its variable substitution. Bit hacky using eval.
    grep "image:" "${INPUT_FILE}" | 
      sed -e 's/\s*image:\s*/echo /g' | 
      while read -r line; do
        eval "${line}"
      done 
  ) | sort | uniq > "${VERSIONS_FILE}"

  echo -e "${GREEN}Using container versions:${NC}"

  while read -r line; do
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
  # shellcheck disable=SC2034
  local -r SERVICES=("${@:3}")
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r STACK_DEFINITIONS_DIR="stack_definitions/${BUILD_STACK_NAME}"
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}/config"
  mkdir -p "${WORKING_DIRECTORY}"
  local -r INPUT_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.yml"
  local -r OUTPUT_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.env"
  local -r OVERRIDE_FILE="${STACK_DEFINITIONS_DIR}/overrides.env"
  local -r WHITELIST_FILE="${STACK_DEFINITIONS_DIR}/env_vars_whitelist.txt"
  local -r VERSIONS_FILE="${WORKING_DIRECTORY}/../VERSIONS.txt"

  create_config
  add_env_vars

    # Sort and de-duplicate param list before we do anything else with the file
    sort -o "${OUTPUT_FILE}" -u "${OUTPUT_FILE}"
    create_versions_file
  }

main "$@"
