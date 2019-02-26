#!/usr/bin/env bash

# Creates scripts to run stacks

set -e

source lib/shell_utils.sh
source lib/stroom_utils.sh

create_script() {
  local script_name=$1
  local SCRIPT_PATH="${WORKING_DIRECTORY}/${script_name}.sh"
  sed \
    "s/<STACK_NAME>/${BUILD_STACK_NAME}/g" \
    "${LIB_DIRECTORY}/template_${script_name}.sh" \
    > "${SCRIPT_PATH}"
  chmod u+x "${SCRIPT_PATH}"
}

main() {
  setup_echo_colours

  [ "$#" -ge 2 ] \
    || die "${RED}Error${NC}: Invalid arguments, usage: " \
      "${BLUE}build.sh stackName serviceX serviceY etc.${NC}"

  echo -e "${GREEN}Copying stack management scripts${NC}"

  local -r BUILD_STACK_NAME=$1
  local -r VERSION=$2
  local -r SERVICES=( "${@:3}" )
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r LIB_DIRECTORY='lib'
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}"

  mkdir -p "${WORKING_DIRECTORY}"

  if element_in "stroom-all-dbs" "${SERVICES[@]}"; then
    create_script backup_databases
  fi

  create_script config

  # Only dropwiz apps need the health script
  if element_in "stroom" "${SERVICES[@]}" \
    || element_in "stroom-proxy-local" "${SERVICES[@]}" \
    || element_in "stroom-proxy-remote" "${SERVICES[@]}" \
    || element_in "stroom-auth-service" "${SERVICES[@]}"; then
    create_script health
  fi

  create_script info
  create_script logs
  create_script remove
  create_script restart

  # Send data script only need if we have a stroom or a proxy
  if element_in "stroom" "${SERVICES[@]}" \
    || element_in "stroom-proxy-local" "${SERVICES[@]}" \
    || element_in "stroom-proxy-remote" "${SERVICES[@]}"; then
    create_script send_data
  fi

  create_script start
  create_script status
  create_script stop

  cp lib/README.md "${WORKING_DIRECTORY}"

  # Copy libs to build
  local -r DEST_LIB="${WORKING_DIRECTORY}/lib"
  mkdir -p "${DEST_LIB}"
  cp lib/banner.txt "${DEST_LIB}"
  cp lib/network_utils.sh "${DEST_LIB}"
  cp lib/shell_utils.sh "${DEST_LIB}"
  cp lib/stroom_utils.sh "${DEST_LIB}"
}

main "$@"
