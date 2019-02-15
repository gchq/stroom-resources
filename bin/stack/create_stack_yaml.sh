#!/usr/bin/env bash
#
# Use this script to create a single YAML file from the existing services.

set -e

# shellcheck disable=SC1091
source lib/shell_utils.sh


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
  echo -e "${GREEN}Adding volumes to docker compose YAML file${NC}"
  local -r MASTER_YAML="../compose/everything.yml"

  # Read the volume whitelist into an array
  local volume_whitelist=()
  if [ -f "${VOLUMES_WHITELIST_FILE}" ]; then
    while read line; do
      # Add a colon to the end as that is how we see them in the master yml file
      volume_whitelist+=("${line}")
    done < "${VOLUMES_WHITELIST_FILE}"
  else
    echo -e "${YELLOW}WARN${NC}: Volume whitelist file ${BLUE}${VOLUMES_WHITELIST_FILE}${NC} not found."
    echo -e "No docker volumes will be added to the stack"
  fi

  # grab all content from master yaml file after and including 'volumes:' entry
  # and ignoring comments and blank lines
  local all_volumes
  all_volumes="$(sed -n -e '/^\w*volumes:/,$p' "${MASTER_YAML}" |
    grep -vP '^\w*#' | 
    grep -v '^\w*$' )"

  echo "${all_volumes}" | while read vol; do
    if [ "${vol}" = "volumes:" ]; then
      echo "${vol}" >> "${OUTPUT_FILE}"
    else
      local trimmed_vol="${vol%%:}"
      if element_in "${trimmed_vol}" "${volume_whitelist[@]}"; then
        echo -e "  ${BLUE}${trimmed_vol}${NC}"

        # indent is important here as it is yaml
        echo "  ${vol}" >> "${OUTPUT_FILE}"
      fi
    fi
  done
}

main() {
  setup_echo_colours

  local -r BUILD_STACK_NAME=$1
  local -r VERSION=$2
  local -r SERVICES=("${@:3}")
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r STACK_DEFINITIONS_DIR="stack_definitions/${BUILD_STACK_NAME}"
  local -r VOLUMES_WHITELIST_FILE="${STACK_DEFINITIONS_DIR}/volumes_whitelist.txt"
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}/config"

  mkdir -p "$WORKING_DIRECTORY"
  local -r OUTPUT_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.yml"

  create_stack_from_services "${SERVICES[@]}" > "${OUTPUT_FILE}"
  append_shared_volumes
}

main "$@"
