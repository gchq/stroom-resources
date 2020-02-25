#!/usr/bin/env bash

############################################################################
# 
#  Copyright 2020 Crown Copyright
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

CMD_HELP_EXTRA_ARGS="package_or_class_1 new_log_level_1 [package_or_class_N new_log_level_2]..."
CMD_HELP_MSG="Sets the log level for a class/package.\nThe change is temporary and will be lost on application restart.\nOnce set it cannot be unset, but you can change its log level to something else.\ne.g:   $0 stroom.startup.App TRACE stroom.security DEBUG\n       $0 stroom.startup.App INFO"

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
{
  source "${DIR}"/lib/network_utils.sh
  source "${DIR}"/lib/shell_utils.sh
  source "${DIR}"/lib/stroom_utils.sh
  source "${DIR}"/lib/constants.sh
}

# This line MUST be before we source the env file, as HOST_IP may be set
# in the env file and thus needs to override the HOST_IP determined here.
# shellcheck disable=SC2034
HOST_IP=$(determine_host_address)

# Read the file containing all the env var exports to make them
# available to docker-compose
# shellcheck disable=SC1090
source "$DIR"/config/<STACK_NAME>.env

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>" 

#readonly URL="http://127.0.0.1:8081/stroomAdmin/tasks/log-level"
readonly CURL="curl"
readonly HTTPIE="http"

send_request() {
  local url="$1"; shift
  local package_or_class=$1; shift
  local new_log_level=$1; shift

  echo -e "Setting ${GREEN}${package_or_class}${NC} to ${GREEN}${new_log_level}${NC}"
  echo

  if [ "${binary}" = "${HTTPIE}" ]; then
    local extra_httpie_args=()
    if [ "${MONOCHROME}" = true ]; then
      # Tell httpie to run in black and white
      extra_httpie_args+=( "--style" "bw" )
    fi
    ${HTTPIE} \
      "${extra_httpie_args[@]}" \
      --body \
      -f POST \
      "${url}" \
      logger="${package_or_class}" \
      level="${new_log_level}"
  else
    ${CURL} \
      -X POST \
      -d "logger=${package_or_class}&level=${new_log_level}" \
      "${url}"
  fi
}

die_invalid_args() {
  echo -e "${RED}Error${NC}: Invalid arguments"
  show_usage
  exit 1
}

show_usage() {
  show_default_usage "[SERVICE] ${CMD_HELP_EXTRA_ARGS}" "${CMD_HELP_MSG}"
  show_services_usage_part
}

main() {
  while getopts ":hm" arg; do
    case $arg in
      h )  
        show_usage
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
      \? )  
        die_invalid_args
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  local remaining_arg_count="$#"

  setup_echo_colours

  if [ "${remaining_arg_count}" -lt 3 ] \
    || [ $((remaining_arg_count % 2)) -ne 1 ]; then

    die_invalid_args
  fi

  local requested_service="$1"; shift

  if [[ "${requested_service}" =~ ^-.* ]]; then
    echo -e "${RED}Error${NC}: Invalid arguments"
    show_usage
    exit 1
  fi

  if ! is_service_in_stack "${requested_service}"; then
    die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not" \
      "in the stack."
  fi

  if ! is_container_running "${requested_service}"; then
    die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not" \
      "running."
  fi

  if ! element_in "${requested_service}" "${SERVICES_WITH_HEALTH_CHECK[@]}"; then
    die "${RED}Error${NC}: You cannot set log levels for ${BLUE}${requested_service}${NC}."
  fi

  check_binary_is_available "${HTTPIE}" "${CURL}"

  # Check if Httpie is installed as it is preferable to curl
  if command -v "${HTTPIE}" 1>/dev/null; then 
    binary="${HTTPIE}"
  else
    binary="${CURL}"
  fi

  # Build the url to send to 
  local admin_port_env_var_name="${ADMIN_PORT_ENV_VAR_NAMES_MAP["${requested_service}"]}"
  local admin_path_name="${ADMIN_PATH_NAMES_MAP["${requested_service}"]}"
  local admin_port=
  admin_port="$(get_config_env_var "${admin_port_env_var_name}")"
  local log_level_url="http://localhost:${admin_port}/${admin_path_name}/tasks/log-level"

  echo -e "Using URL ${BLUE}${log_level_url}${NC}"
  echo

  #loop through the remaining pairs of args
  while [ $# -gt 0 ]; do
    package_or_class="$1"
    new_log_level="$2"

    send_request "${log_level_url}" "${package_or_class}" "${new_log_level}"

    #bin the two args we have just used
    shift 2
  done

  echo -e "${GREEN}Done${NC}"
}

main "$@"
# vim:sw=2:ts=2:et:
