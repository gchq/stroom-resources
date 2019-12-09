#!/usr/bin/env bash
#
# Use this script to create a single YAML file from the existing services.

set -e

# shellcheck disable=SC1091
source lib/shell_utils.sh

old_create_stack_from_services() {
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

create_stack_from_services() {

  local compose_args=()
  local target_file

  # Add in the special root file first. This MUST come first
  # as all other paths are relative to this.
  compose_args+=( "-f" "${ROOT_YAML_FILE}" )

  echo "Named vols"
  # Add any named volume files first (if the service has one)
  for service in "${SERVICES[@]}"; do
    target_file="${NAMED_VOLUMES_DIR}/${service}${NAMED_VOLUMES_SUFFIX}.yml"

    if [ -f "${target_file}" ]; then
      # path needs to be relative to home of root yml file
      #compose_args+=( \
        #"-f" \
        #"$(realpath --relative-to="${CONTAINERS_DIR}" "${target_file}")" \
      #)
      #echo "  $(realpath --relative-to="${CONTAINERS_DIR}" "${target_file}")"

      compose_args+=( "-f" "${target_file}" )
      echo "  ${target_file}"
    fi
  done

  echo "Service files"
  # Add the actual service files
  for service in "${SERVICES[@]}"; do
    target_file="${CONTAINERS_DIR}/${service}.yml"
    #compose_args+=( \
      #"-f" \
      #"$(realpath --relative-to="${CONTAINERS_DIR}" "${target_file}")" \
      #)
    #echo "  $(realpath --relative-to="${CONTAINERS_DIR}" "${target_file}")"
    compose_args+=( "-f" "${target_file}" )
    echo "  ${target_file}"
  done

  echo "Override files"
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

    echo "[${target_service}] [${source_service}]"

    if element_in "${target_service}" "${SERVICES[@]}" \
      && element_in "${source_service}" "${SERVICES[@]}"; then
      # both target and source are in the stack servcies so include this
      # override file

      #compose_args+=( \
        #"-f" \
        #"$(realpath --relative-to="${CONTAINERS_DIR}" "${vol_mount_file}")" \
      #)
      #echo "  $(realpath --relative-to="${CONTAINERS_DIR}" "${vol_mount_file}")"
      compose_args+=( "-f" "${vol_mount_file}" )
      echo "  ${vol_mount_file}"
    fi
  done

  echo "compose args: ${compose_args[*]}"
  pwd

  docker-compose "${compose_args[@]}" config > "${OUTPUT_FILE}"
}

main() {
  setup_echo_colours

  local -r BUILD_STACK_NAME=$1
  local -r VERSION=$2
  local -r SERVICES=("${@:3}")
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}/config"

  mkdir -p "$WORKING_DIRECTORY"
  local -r OUTPUT_FILE="${WORKING_DIRECTORY}/${BUILD_STACK_NAME}.yml"
  local -r CONTAINERS_DIR="../compose/containers"
  local -r ROOT_YAML_FILE="${CONTAINERS_DIR}/root.yml"
  local -r NAMED_VOLUMES_DIR="${CONTAINERS_DIR}/named_volumes"
  local -r NAMED_VOLUME_MOUNTS_DIR="${CONTAINERS_DIR}/named_volume_mounts"

  local -r NAMED_VOLUMES_SUFFIX="_volumes"

  #create_stack_from_services "${SERVICES[@]}" > "${OUTPUT_FILE}"
  create_stack_from_services "${SERVICES[@]}"
}

main "$@"
