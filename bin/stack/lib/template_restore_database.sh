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

#######################################################################
#    Restores a single database using the provded dump and db name    #
#######################################################################

set -e

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

readonly LOCK_FILE=${DIR}/$(basename "$0").lck
readonly THIS_PID=$$
readonly DB_CONTAINER_ID="stroom-all-dbs"

# The list of databases to backup
readonly DATABASES=( \
  "${STROOM_AUTH_DB_NAME:-auth}"
  "${STROOM_DB_NAME:-stroom}"
  "${STROOM_STATS_DB_NAME:-stats}"
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
    echo -e "See ${BLUE}https://docs.docker.com/install/#supported-platforms${NC}" \
      "for details on how to install it"
    echo -e "Version ${BLUE}17.12.0${NC} or higher is required"
    exit 1
  fi
}

display_usage_and_exit() {
  echo -e "Usage: $(basename "$0") [OPTIONS] db_name db_dump_file" >&2
  echo -e "-f           - Force the import if the destination DB is not empty" >&2
  echo -e "-h           - Show this help" >&2
  echo -e "-m           - Monochrome output" >&2
  echo -e "db_name      - the database to import db_dump_file into" >&2
  echo -e "db_dump_file - the dump file to import, e.g. stats_20210217134922.sql.gz" >&2
  exit 1
}

get_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        local lock_file_pid
        lock_file_pid=$(head -n 1 "${LOCK_FILE}")
        if ps -p "$lock_file_pid" > /dev/null; then
            err "This script is already running as process" \
              "${BLUE}${lock_file_pid}${NC}! Exiting."
            exit 0
        else 
            echo -e "Found old lock file for a process that is no longer running!"
            echo -e "Did a previous run of this script fail? I will delete it" \
              "and create a new one."
            echo -e "Creating a lock file for process ${BLUE}${THIS_PID}${NC}"
            echo "$$" > "${LOCK_FILE}"
        fi
    else
        echo -e "Creating a lock file for process ${BLUE}${THIS_PID}${NC}"
        echo "$$" > "${LOCK_FILE}"
    fi
}

verify_db() {
  local -r db_name="$1"

  local cmd=""
  cmd+="echo"
  cmd+=" 'select count(*)"
  cmd+=" from information_schema.tables"
  cmd+=" where table_schema = database();'"
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

    if [[ "${output}" -gt 0  && "${force_import}" = false ]]; then
      echo
      echo -e "${RED}WARNING:${NC} ${GREEN}This database is not empty do you wish to continue?${NC}"
      echo
      read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

      if [ "$keyPressed" = 'y' ] || [ "$keyPressed" = 'Y' ]; then
        # Crack on
        echo
      else
        echo
        echo "Exiting"
        exit 0
      fi
    fi
  fi
}

restore_db() {
  local -r db_name="$1"
  local -r db_dump_file="$2"

  local db_dump_file

  echo -e "${GREEN}Starting restore of ${BLUE}${db_dump_file}${NC} into database" \
    "${BLUE}${db_name}${NC}"

  local start_time
  local end_time
  start_time="$(date +%s)"
  # Run the backup inside the container, redirecting the output to a gzipped file on the host
  
  local cmd=()
  cmd+="/usr/bin/mysql"
  cmd+="-uroot -p\"${root_password}\" "
  cmd+="${db_name}"

  cmd=(
    "/usr/bin/mysql"
    "-uroot"
    "--password=${root_password}"
    "${db_name}")

  gunzip < "${db_dump_file}" \
    | docker exec -i "${DB_CONTAINER_ID}" \
    "${cmd[@]}"

  end_time="$(date +%s)"
  local duration=$(( end_time - start_time ))

  echo -e "${GREEN}Completed restore of dump file ${BLUE}${db_dump_file}${NC} in" \
    "${BLUE}${duration}${NC} seconds"
}

check_container_is_running() {
  local is_running
  is_running=$(docker inspect -f "{{.State.Running}}" "${DB_CONTAINER_ID}" 2>/dev/null)

  if [ "${is_running}" != "true" ]; then
      die "${RED}Error${NC}:" \
        "Docker container ${BLUE}${DB_CONTAINER_ID}${NC} is not running." \
        "Unable to perform backup."
  fi
}

main() {
  # assume not monchrome until we know otherwise
  setup_echo_colours
  local force_import=false
  while getopts ":fmh" arg; do
    # shellcheck disable=SC2034
    case $arg in
      f )  
        force_import=true 
        ;;
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

  local -r db_name=$1
  local -r db_dump_file=$2
  check_installed_binaries

  if [ "${db_name}x" = "x" ]; then
    err "${RED}Error${NC}: Invalid arguments, missing db_name"
    display_usage_and_exit
  fi

  if [ "${db_dump_file}x" = "x" ]; then
    err "${RED}Error${NC}: Invalid arguments, missing db_dump_file"
    display_usage_and_exit
  fi

  if [ ! -f "${db_dump_file}" ]; then
    die "${RED}Error${NC}: db_dump_file ${BLUE}${db_dump_file}${NC} doesn't exist"
  fi

  check_container_is_running
  get_lock

  verify_db "${db_name}"

  restore_db "${db_name}" "${db_dump_file}"

  echo -e "Deleting lock file for process ${BLUE}${THIS_PID}${NC}"
  rm "${LOCK_FILE}" \
    || (err "Unable to delete lock file ${BLUE}${LOCK_FILE}${NC}" && exit 1)
  echo -e "${GREEN}Done${NC}"
}

main "$@"
