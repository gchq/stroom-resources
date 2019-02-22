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
  rm -f "${OUTPUT_ENV_FILE}"
  touch "${OUTPUT_ENV_FILE}"
  chmod +x "${OUTPUT_ENV_FILE}"
}

# If var_name is "STROOM_TAG", replacement_value is "v6.1.2" and a line in
# ${INPUT_YAML_FILE} looks like:
#   image: "${STROOM_REPO:-gchq/stroom}:${STROOM_TAG:-v6.0-LATEST}"
# then it becomes 
#   image: "${STROOM_REPO:-gchq/stroom}:v6.1.2"
replace_in_yaml() {
  local -r var_name="$1"
  local -r replacement_value="$2"
  local -r regex="\\$\{${var_name}(:-?[^}]*)?}"

  #echo "${regex}"

  if grep -E --silent "${regex}" "${INPUT_YAML_FILE}"; then
    echo -e "  Overriding the value of ${YELLOW}${var_name}${NC} to ${BLUE}${replacement_value}${NC}"
    sed -i'' -E "s|${regex}|${replacement_value}|g" "${INPUT_YAML_FILE}"
  fi
}

#override_container_versions() {
  ## force a sub-shell so the sourcing doesn't pollute our shell
  #(
    ## source the file so we can read the override values
    ## shellcheck disable=SC1091
    #source "${CONTAINER_VERSIONS_FILE}"

    ## Implicit sub-shell doesn't matter as we are not modifying any outer variables
    #grep -E "^[ \t]*[A-Z0-9_]+=.*" "${CONTAINER_VERSIONS_FILE}" | while read -r line; do
      #local var_name="${line%%=*}"
      ## We have sourced the container version file so use bash indirect expansion
      ## ('!') to get the value of var_name
      #local var_value="${!var_name}"
      ##echo "var_name: [${var_name}], var_value: [${var_value}]"

      #replace_in_yaml "${var_name}" "${var_value}"
    #done
  #)
#}

apply_overrides_to_yaml() {

  local -r override_file="$1"
  # force a sub-shell so the sourcing doesn't pollute our shell
  (
    # source the file so we can read the override values
    # shellcheck disable=SC1091
    source "${override_file}"

    grep -oE "^[ \t]*[A-Z0-9_]+=.*" "${override_file}" | while read -r line; do
      # Extract the var name and value from the override file line
      local var_name="${line%%=*}"
      # remove leading whitespace characters
      var_name="${var_name#"${var_name%%[![:space:]]*}"}"
      # We have sourced the container version file so use bash indirect expansion
      # ('!') to get the value of var_name
      local var_value="${!var_name}"
      #echo "var_name: [${var_name}], var_value: [${var_value}]"

      replace_in_yaml "${var_name}" "${var_value}"
    done
  )
}

add_env_vars() {
  local -r CONTAINER_VERSIONS_FILE="container_versions.env"
  # Associative array to hold whitelisted_var_name => use_count
  declare -A whitelisted_use_counters

  # Associative array to hold var_name => var_value
  declare -A output_env_vars

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
    echo -e "${GREEN}Adding white-listed environment variables to ${BLUE}${OUTPUT_ENV_FILE}${NC}"
    touch "${OUTPUT_ENV_FILE}"
  else
    echo -e "${RED}Warn${NC}: Environment variable whitelist file ${BLUE}${WHITELIST_FILE}${NC} not found."
    echo -e "${GREEN}Adding ALL environment variables to ${BLUE}${OUTPUT_ENV_FILE}${NC}"
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
    grep -v "\w* echo" "${INPUT_YAML_FILE}" |
      # Extracts the params
      grep -Po "(?<=\\$\\{).*?(?=\\})" |
      # ignore commented lines
      grep -v '^\w*#' |
      # Replaces ':-' with '='
      sed "s/:-/=/g" )

  # associative array to hold var_name => count
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
      #echo "export ${env_var_name_value}" >> "${OUTPUT_ENV_FILE}"

      # Add the env var to our assoc. array
      output_env_vars["${var_name}"]="${var_value}"
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

  # OUTPUT_ENV_FILE contains stuff like STROOM_TAG=v6.0-LATEST, i.e. development
  # docker tags, so we need to replace them with fixed versions from 
  # CONTAINER_VERSIONS_FILE. 

  echo -e "${GREEN}Setting container versions${NC}"
  #override_container_versions
  apply_overrides_to_yaml "${CONTAINER_VERSIONS_FILE}"

  ## force a sub-shell so the sourcing doesn't pollute our shell
  #(
    ## source the file so 
    ## shellcheck disable=SC1091
    #source ${CONTAINER_VERSIONS_FILE}

    ## Implicit sub-shell doesn't matter as we are not modifying any outer variables
    #grep -E "^\s*STROOM[A-Z0-9_]*_TAG=.*" ${CONTAINER_VERSIONS_FILE} | while read -r line; do
      #local var_name="${line%%=*}"
      ## We have sourced the container version file so use bash indirect expansion
      ## ('!') to get the value of var_name
      #local var_value="${!var_name}"
      ##echo "var_name: [${var_name}], var_value: [${var_value}]"

      #replace_in_yaml "${var_name}" "${var_value}"
    #done
  #)

  # If there is a override file then replace any matching env
  # vars found in the OUTPUT_ENV_FILE with the values from the override file.
  # This allows a stack to differ slightly from the defaults taken from the yml
  if [ -f "${OVERRIDE_FILE}" ]; then
    echo -e "${GREEN}Applying variable overrides${NC}"
    apply_overrides_to_yaml "${OVERRIDE_FILE}"
  fi
}

create_versions_file() {

  # Produce a list of fully qualified docker image tags by sourcing the OUTPUT_ENV_FILE
  # that contains all the env vars and using their values to do variable substitution
  # against the image definitions obtained from the yml (INPUT_YAML_FILE)
  # Source the env file in a subshell to avoid poluting ours
  # shellcheck disable=SC1090
  ( 
    source "${OUTPUT_ENV_FILE}"

    # Find all image: lines in the yml and turn them into echo statements so we can
    # eval them so bash does its variable substitution. Bit hacky using eval.
    grep "image:" "${INPUT_YAML_FILE}" | 
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
  local -r INPUT_YAML_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.yml"
  local -r OUTPUT_ENV_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.env"
  local -r OVERRIDE_FILE="${STACK_DEFINITIONS_DIR}/overrides.env"
  local -r WHITELIST_FILE="${STACK_DEFINITIONS_DIR}/env_vars_whitelist.txt"
  local -r VERSIONS_FILE="${WORKING_DIRECTORY}/../VERSIONS.txt"

  echo -e "${GREEN}Setting stack name in yaml file${NC}"
  replace_in_yaml "STACK_NAME" "${BUILD_STACK_NAME}"

  create_config
  add_env_vars

    # Sort and de-duplicate param list before we do anything else with the file
    sort -o "${OUTPUT_ENV_FILE}" -u "${OUTPUT_ENV_FILE}"
    create_versions_file
  }

main "$@"
