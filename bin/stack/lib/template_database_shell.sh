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

set -e

# Opens a MySQL shell in the stroom database

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

readonly THIS_PID=$$
readonly DB_CONTAINER_ID="stroom-all-dbs"

# The list of databases to backup
readonly STROOM_DB="${STROOM_DB_NAME:-stroom}"
readonly STATS_DB="${STROOM_STATS_DB_NAME:-stats}"
readonly DEFAULT_DB="${STROOM_DB}"
readonly DATABASES=(
  "${STROOM_DB}"
  "${STATS_DB}"
)

source "${DIR}"/lib/shell_utils.sh
source "${DIR}"/lib/stroom_utils.sh
source "${DIR}"/lib/constants.sh

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env
# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>" 

check_installed_binaries() {
  # The version numbers mentioned here are mostly governed by the docker compose syntax version that 
  # we use in the yml files, currently 2.4, see https://docs.docker.com/compose/compose-file/compose-versioning/

  if ! command -v docker 1>/dev/null; then 
    echo -e "${RED}Error${NC}: Docker CE is not installed!"
    echo -e "See ${BLUE}https://docs.docker.com/install/#supported-platforms${NC} for details on how to install it"
    echo -e "Version ${BLUE}17.12.0${NC} or higher is required"
    exit 1
  fi
}

display_usage_and_exit() {
  cmd_help_args="[DATABASE]"
  cmd_help_msg="Opens a MySQL command line interface to DATABASE or '${STROOM_DB}' if not supplied."
  show_default_usage "${cmd_help_args}" "${cmd_help_msg}"
  exit 1
}

open_db_shell() {
  local db_name="$1"; shift
  local db_port="$1"; shift
  local db_username="$1"; shift
  local db_password="$1"; shift

  local extra_docker_args=()
  # Check for terminal on stdin, which will be false when sql is piped
  # to this script, e.g. 'show tables;' | ./database_shell.sh
  if [ -t 0 ]; then
    # stdin is a terminal so tell docker that
    extra_docker_args=( 
      "--tty"
    )
  fi
  
  docker exec \
    "${extra_docker_args[@]}" \
    --interactive \
    stroom-all-dbs \
    mysql \
    --table \
    -h"localhost" \
    -P"${db_port}" \
    -u"${db_username}" \
    -p"${db_password}" \
    "${db_name}"
}

check_container_is_running() {
  local is_running
  is_running=$( \
    docker inspect \
      -f "{{.State.Running}}" \
      "${DB_CONTAINER_ID}" \
    2>/dev/null \
    || echo "false")

  if [ "${is_running}" != "true" ]; then
      die "${RED}Error${NC}:" \
        "Docker container ${BLUE}${DB_CONTAINER_ID}${NC} is not running."
  fi
}

validate_db_name() {
  local db_name="$1"; shift
  local is_valid=false
  for valid_name in "${DATABASES[@]}"; do
    if [[ "${valid_name}" = "${db_name}" ]]; then
      is_valid=true   
      break
    fi
  done

  if [[ "${is_valid}" = "false" ]]; then
    die "${RED}Error${NC}:" \
      "Database ${BLUE}${db_name}${NC} is not valid." \
          "Valid names are [${BLUE}${DATABASES[*]}${NC}]."
  fi
}

main() {
  # assume not monchrome until we know otherwise
  setup_echo_colours
  while getopts ":mh" arg; do
    # shellcheck disable=SC2034
    case $arg in
      h ) 
        display_usage_and_exit
        ;;
      m )  
        MONOCHROME=true 
        ;;
      * ) 
        err "${RED}Error${NC}: Invalid arguments"
        display_usage_and_exit
        ;;  # getopts already reported the illegal option
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  local db_name
  if [[ $# -eq 1 ]]; then
    db_name="${1}"
    validate_db_name "${db_name}"
  else
    db_name="${DEFAULT_DB}"
  fi

  setup_echo_colours

  local password
  local username
  local port
  if [[ "${db_name}" = "${STROOM_DB}" ]]; then
    password="$(get_config_env_var "STROOM_DB_PASSWORD")"
    username="$(get_config_env_var "STROOM_DB_USERNAME")"
    port="$(get_config_env_var "STROOM_DB_PORT")"
  elif [[ "${db_name}" = "${STATS_DB}" ]]; then
    password="$(get_config_env_var "STROOM_STATS_DB_PASSWORD")"
    username="$(get_config_env_var "STROOM_STATS_DB_USERNAME")"
    port="$(get_config_env_var "STROOM_STATS_DB_PORT")"
  fi

  check_installed_binaries

  check_container_is_running

  echo -e "Connecting to database ${BLUE}${db_name}${NC} with" \
    "username ${BLUE}${username}${NC}"

  open_db_shell "${db_name}" "${port}" "${username}" "${password}"
}

main "$@"
