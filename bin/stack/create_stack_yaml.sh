#!/usr/bin/env bash
#
# Use this script to create a single YAML file from the existing services.

set -e

# shellcheck disable=SC1091
source lib/shell_utils.sh

# If var_name is "STROOM_TAG", replacement_value is "v6.1.2" and a line in
# ${INPUT_YAML_FILE} looks like:
#   image: "${STROOM_DOCKER_REPO:-gchq/stroom}:${STROOM_TAG:-v6.0-LATEST}"
# then it becomes 
#   image: "${STROOM_DOCKER_REPO:-gchq/stroom}:${STROOM_TAG:-v6.1.2}"
# This changes the default value, whilst still allowing it to be overridden
# via the env file at deployment time.
replace_in_yaml_file() {
  local -r file="$1"; shift
  local -r var_name="$1"; shift
  local -r replacement_value="\${${var_name}:-$1}"; shift
  local -r regex="\\$\{${var_name}(:-?[^}]*)?}"

  #echo "${regex}"

  if grep -E --silent "${regex}" "${file}"; then
    echo -e "    Overriding the value of ${YELLOW}${var_name}${NC} to ${BLUE}${replacement_value}${NC}"
    sed -i'' -E "s|${regex}|${replacement_value}|g" "${file}"
  fi
}

add_yaml_file_to_stack() {
  local file="$1"; shift

  # The order that the files are used as arguments to docker compose
  # is important so we need to prefix with a counter
  printf -v file_prefix "%02d_" "${file_counter}"

  local filename
  filename="$(basename "${file}")"
  local new_filename="${file_prefix}${filename}"
  dest_file="${WORKING_DIRECTORY}/${new_filename}"

  echo -e "  Copying ${BLUE}${file}${NC} ${YELLOW}=>${NC} ${BLUE}${new_filename}${NC}"
  cp "${file}" "${dest_file}"

  replace_in_yaml_file "${dest_file}" "STACK_NAME" "${BUILD_STACK_NAME}"
  # Increment the counter
  file_counter=$((file_counter + 1))
}

create_stack_from_services() {
  echo -e "${GREEN}Copying the yaml file(s) to the stack${NC}"

  local target_file
  local file_counter=0

  # Add any named volume files first (if the service has one)
  for service in "${SERVICES[@]}"; do
    target_file="${NAMED_VOLUMES_DIR}/${service}${NAMED_VOLUMES_SUFFIX}.yml"

    if [ -f "${target_file}" ]; then
      add_yaml_file_to_stack "${target_file}"
    fi
  done

  # Add the actual service files
  for service in "${SERVICES[@]}"; do
    target_file="${CONTAINERS_DIR}/${service}.yml"
    add_yaml_file_to_stack "${target_file}"
  done

  # Add any volume mount files if they are applicable for this stack
  for vol_mount_file in ${NAMED_VOLUME_MOUNTS_DIR}/*.yml; do
    # filename format is serviceX_serviceY.yml, where serviceX is the service
    # that is having the volume mount and serviceY is the service it is sharing
    # it with.
    local filename
    filename="$(basename "${vol_mount_file}" )"
    filename="${filename%%\.yml}"
    local target_service="${filename%%_*}"
    local source_service="${filename##*_}"

    #echo "[${target_service}] [${source_service}]"

    if element_in "${target_service}" "${SERVICES[@]}" \
      && element_in "${source_service}" "${SERVICES[@]}"; then
      # both target and source are in the stack servcies so include this
      # override file
      add_yaml_file_to_stack "${vol_mount_file}"
    fi
  done
}

main() {
  setup_echo_colours

  local -r BUILD_STACK_NAME=$1
  local -r VERSION=$2
  local -r SERVICES=("${@:3}")
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}/config"

  mkdir -p "$WORKING_DIRECTORY"
  local -r CONTAINERS_DIR="../compose/containers"
  local -r NAMED_VOLUMES_DIR="${CONTAINERS_DIR}/named_volumes"
  local -r NAMED_VOLUME_MOUNTS_DIR="${CONTAINERS_DIR}/named_volume_mounts"

  local -r NAMED_VOLUMES_SUFFIX="_volumes"

  create_stack_from_services "${SERVICES[@]}"
}

main "$@"
