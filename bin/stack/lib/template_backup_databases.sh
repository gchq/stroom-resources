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

# Starts the stack, using the configuration defined in the .env file.

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

readonly LOCK_FILE=${DIR}/$(basename "$0").lck
readonly THIS_PID=$$
readonly DB_CONTAINER_ID="stroom-all-dbs"

readonly DATABASES=( \
  "auth"
  "stroom"
  "stats" )

source "$DIR"/lib/shell_utils.sh
source "$DIR"/lib/stroom_utils.sh

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
  echo -e "Usage: $(basename "$0") output_dir" >&2
  echo -e "output_dir - the directory to write backup files to" >&2
  exit 1
}

get_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        local lock_file_pid
        lock_file_pid=$(head -n 1 "${LOCK_FILE}")
        if ps -p "$lock_file_pid" > /dev/null; then
            err "This script is already running as process ${BLUE}${lock_file_pid}${NC}! Exiting."
            exit 0
        else 
            echo -e "Found old lock file for a process that is no longer running!"
            echo -e "Did a previous run of this script fail? I will delete it and create a new one."
            echo -e "Creating a lock file for process ${BLUE}${THIS_PID}${NC}"
            echo "$$" > "${LOCK_FILE}"
        fi
    else
        echo -e "Creating a lock file for process ${BLUE}${THIS_PID}${NC}"
        echo "$$" > "${LOCK_FILE}"
    fi
}

run_backups() {
  local output_dir="$1"

  # Use a consistent backup time for all db backups
  local backup_time
  backup_time="$(date +%Y%m%d%H%M%S)"

  for db_name in "${DATABASES[@]}"; do
    verify_db "${db_name}"
    backup_db "${db_name}" "${output_dir}" "${backup_time}"
  done
}

verify_db() {
  local -r db_name="$1"

  local cmd=""
  cmd+="echo 'select count(*) from information_schema.tables where table_schema = database();'"
  cmd+=" | mysql -uroot -p\"${root_password}\" ${db_name} 2>&1"
  cmd+=" | tail -n1"

  local output
  output="$( \
    docker exec "${DB_CONTAINER_ID}" \
      sh -c "${cmd}"
  )"

  if [[ "${output}" =~ ERROR ]] || [[ ! "${output}" =~ [0-9]+ ]]; then
      err "${RED}Error${NC}:" \
        "Verifying connection to database ${BLUE}${db_name}${NC}"
      echo "${output}"
      exit 1
  else
    echo -e "${GREEN}Verified connection to database ${BLUE}${db_name}${NC}." \
      "Table count: ${BLUE}${output}${NC}"
  fi
}

backup_db() {
  local -r db_name="$1"
  local -r output_dir="$2"
  local -r backup_time="$3"

  local output_file
  output_file="${output_dir}/${db_name}_${backup_time}.sql.gz"
  echo -e "${GREEN}Starting backup of database ${BLUE}${db_name}${NC} to ${BLUE}${output_file}${NC}"

  local start_time
  local end_time
  start_time="$(date +%s)"
  # Run the backup inside the container, redirecting the output to a gzipped file on the host
  docker exec "${DB_CONTAINER_ID}" \
    sh -c "exec mysqldump -uroot -p\"${root_password}\" --single-transaction ${db_name}" \
    | gzip > "${output_file}"

  end_time="$(date +%s)"
  local duration=$(( end_time - start_time ))

  echo -e "${GREEN}Completed backup of database ${BLUE}${db_name}${NC} in ${BLUE}${duration}${NC} seconds"
}

check_container_is_running() {
  local is_running
  is_running=$(docker inspect -f "{{.State.Running}}" "${DB_CONTAINER_ID}" 2>/dev/null)

  if [ "${is_running}" != "true" ]; then
      die "${RED}Error${NC}:" \
        "Docker container ${BLUE}${DB_CONTAINER_ID}${NC} is not running. Unable to perform backup."
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

  setup_echo_colours

  local root_password
  root_password="$(get_config_env_var "STROOM_DB_ROOT_PASSWORD")"

  local -r output_dir=$1
  check_installed_binaries

  if [ "${output_dir}x" = "x" ]; then
    err "${RED}Error${NC}: Invalid arguments, missing output_dir"
    display_usage_and_exit
  fi

  if [ ! -d "${output_dir}" ]; then
    die "${RED}Error${NC}: output_dir ${BLUE}${output_dir}${NC} doesn't exist"
  fi

  check_container_is_running
  get_lock

  run_backups "${output_dir}"

  echo -e "Deleting lock file for process ${BLUE}${THIS_PID}${NC}"
  rm "${LOCK_FILE}" || (err "Unable to delete lock file ${BLUE}${LOCK_FILE}${NC}" && exit 1)
  echo -e "${GREEN}Done${NC}"
}

main "$@"
