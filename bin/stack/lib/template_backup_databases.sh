#!/usr/bin/env bash

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

#source "$DIR"/lib/network_utils.sh
source "$DIR"/lib/shell_utils.sh
#source "$DIR"/lib/stroom_utils.sh


# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

check_installed_binaries() {
  # The version numbers mentioned here are mostly governed by the docker compose syntax version that 
  # we use in the yml files, currently 2.4, see https://docs.docker.com/compose/compose-file/compose-versioning/

  if ! command -v docker 1>/dev/null; then 
    echo -e "${RED}ERROR${NC}: Docker CE is not installed!"
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
            err "This script is already running as process ${CYAN}${lock_file_pid}${NC}! Exiting."
            exit 0
        else 
            echo -e "Found old lock file! Did a previous run of this script fail? I will delete it and create a new one."
            echo -e "Creating a lock file for process ${CYAN}${THIS_PID}${NC}"
            echo "$$" > "${LOCK_FILE}"
        fi
    else
        echo -e "Creating a lock file for process ${CYAN}${THIS_PID}${NC}"
        echo "$$" > "${LOCK_FILE}"
    fi
}

run_backups() {
  local output_dir="$1"

  # Use a consistent backup time for all db backups
  local backup_time
  backup_time="$(date +%Y%m%d%H%M%S)"

  for db_name in "${DATABASES[@]}"; do
    backup_db "${db_name}" "${output_dir}" "${backup_time}"
  done
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
    sh -c "exec mysqldump -uroot -p\"${STROOM_DB_ROOT_PASSWORD}\" --single-transaction ${db_name}" \
    | gzip > "${output_file}"

  end_time="$(date +%s)"
  local duration=$(( end_time - start_time ))

  echo -e "${GREEN}Completed backup of database ${BLUE}${db_name}${NC} in ${BLUE}${duration}${NC} seconds"
}

check_container_is_running() {
  local is_running
  is_running=$(docker inspect -f "{{.State.Running}}" "${DB_CONTAINER_ID}" 2>/dev/null)

  if [ "${is_running}" != "true" ]; then
      die "${RED}ERROR${NC}: Docker container ${BLUE}${DB_CONTAINER_ID}${NC} is not running. Unable to perform backup."
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
        err "${RED}ERROR${NC}: Invalid arguments"
        display_usage_and_exit
        ;;  # getopts already reported the illegal option
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  setup_echo_colours

  local -r output_dir=$1
  check_installed_binaries

  if [ "${output_dir}x" = "x" ]; then
    err "${RED}ERROR${NC}: Invalid arguments, missing output_dir"
    display_usage_and_exit
  fi

  if [ ! -d "${output_dir}" ]; then
    die "${RED}ERROR${NC}: output_dir ${BLUE}${output_dir}${NC} doesn't exist"
  fi

  check_container_is_running
  get_lock

  run_backups "${output_dir}"

  echo -e "Deleting lock file for process ${CYAN}${THIS_PID}${NC}"
  rm "${LOCK_FILE}" || (err "Unable to delete lock file ${BLUE}${LOCK_FILE}${NC}" && exit 1)
}

main "$@"
