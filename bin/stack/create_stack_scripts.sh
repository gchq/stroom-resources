#!/usr/bin/env bash

############################################################################
# 
#  Copyright 2019 Crown Copyright
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# 
############################################################################

# Creates scripts to run stacks

set -e

# shellcheck disable=SC1091
{
  source lib/shell_utils.sh
  source lib/stroom_utils.sh
}

create_script() {
  local script_name="$1"
  local source_script_name="template_${script_name}.sh"
  local dest_script_name="${script_name}.sh"
  local SCRIPT_PATH="${WORKING_DIRECTORY}/${dest_script_name}"
  echo -e "  Copying ${BLUE}${source_script_name}${NC}" \
    "${YELLOW}=>${NC} ${BLUE}${SCRIPT_PATH}${NC}"
  sed \
    "s/<STACK_NAME>/${BUILD_STACK_NAME}/g" \
    "${LIB_DIRECTORY}/${source_script_name}" \
    > "${SCRIPT_PATH}"
  chmod u+x "${SCRIPT_PATH}"
}

copy_file() {
  local -r src=$1
  local -r dest_dir=$2
  echo -e "  Copying ${BLUE}${src}${NC} ${YELLOW}=>${NC} ${BLUE}${dest_dir}${NC}"
  mkdir -p "${dest_dir}"
  cp "${src}" "${dest_dir}"
}

main() {
  setup_echo_colours

  [ "$#" -ge 2 ] \
    || die "${RED}Error${NC}: Invalid arguments, usage: " \
      "${BLUE}build.sh stackName serviceX serviceY etc.${NC}"

  echo -e "${GREEN}Copying and substituting stack management script templates${NC}"

  local -r BUILD_STACK_NAME=$1
  local -r VERSION=$2
  local -r SERVICES=( "${@:3}" )
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r LIB_DIRECTORY='lib'
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}"

  mkdir -p "${WORKING_DIRECTORY}"

  if element_in "stroom-all-dbs" "${SERVICES[@]}"; then
    create_script backup_databases
    create_script restore_database
    create_script database_shell
  fi

  # Only stroom can be migrated
  # It is possible the DB is running elsewhere
  if element_in "stroom" "${SERVICES[@]}"; then
    create_script migrate
  fi

  create_script show_config
  create_script pull_images

  # Only dropwiz apps need the health script
  if element_in "stroom" "${SERVICES[@]}" \
    || element_in "stroom-proxy-local" "${SERVICES[@]}" \
    || element_in "stroom-proxy-remote" "${SERVICES[@]}"; then
    create_script health
    create_script set_log_levels
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

  create_script set_services
  create_script start
  create_script status
  create_script stop

  echo -e "${GREEN}Copying stack management lib scripts${NC}"
  # Copy libs to build
  local -r DEST_LIB="${WORKING_DIRECTORY}/lib"
  mkdir -p "${DEST_LIB}"
  copy_file lib/banner.txt "${DEST_LIB}"
  copy_file lib/constants.sh "${DEST_LIB}"
  copy_file lib/network_utils.sh "${DEST_LIB}"
  copy_file lib/shell_utils.sh "${DEST_LIB}"
  copy_file lib/stroom_utils.sh "${DEST_LIB}"

  echo -e "${GREEN}Copying assorted files to stack root${NC}"
  copy_file lib/README.md "${WORKING_DIRECTORY}"
  copy_file lib/LICENCE.txt "${WORKING_DIRECTORY}"
}

main "$@"
