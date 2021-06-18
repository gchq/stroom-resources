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


# Shows the stacks logs

cmd_help_msg="Tails the logs for the specified services or all services if none are supplied."
cmd_help_options="  -n N Set the number of previous lines to display per service (or 'all'), default is 5."
line_count_per_service="20"
extra_compose_args=()

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}"/lib/shell_utils.sh
source "${DIR}"/lib/stroom_utils.sh
source "${DIR}"/lib/constants.sh

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>" 

main() {

  # leading colon means silent error reporting by getopts
  while getopts ":mhn:" arg; do
    case $arg in
      h )  
        show_default_services_usage "${cmd_help_msg}" "${cmd_help_options}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        extra_compose_args+=( "--no-color" )
        ;;
      n )  
        line_count_per_service="${OPTARG}"
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  local running_service_count
  running_service_count="$(
    docker ps \
      --filter "label=stack_name=<STACK_NAME>" \
      --format  "{{.ID}}" \
      | wc -l
  )"

  if [ "${running_service_count}" -eq 0 ]; then
    die "${RED}Error${NC}: No services are running."
  fi

  for requested_service in "${@}"; do
    if ! is_service_in_stack "${requested_service}"; then
      die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not in the stack."
    fi
    if ! is_container_running "${requested_service}"; then
      die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not running."
    fi
  done
  # Extract the services column from the SERVICES file and add each to the array
  local stack_services=()
  # shellcheck disable=SC2154
  while read -r service_to_start; do
    stack_services+=( "${service_to_start}" )
  done <<< "$( cut -d "|" -f 1 < "${DIR}/${STACK_SERVICES_FILENAME}" )"

  # Explicitly set services to show logs for so we can use the SERVICES file to
  # control what services run on the node.
  if [ "$#" -eq 0 ]; then
    extra_compose_args=( "${stack_services[@]}" )
  else
    extra_compose_args=( "${@}" )
  fi

  #echo "Remaining args: [${*}]"

  # Has to be called after MONOCHROME has had a chance to be set
  setup_echo_colours

  if [ "${line_count_per_service}" == "all" ]; then
    echo -e "${GREEN}Tailing the logs from the first entry onwards" \
      "(ctlr-c to exit)${NC}"
  else
    echo -e "${GREEN}Tailing the logs from the last ${line_count_per_service}" \
      "entries onwards (ctlr-c to exit)${NC}"
  fi

  run_docker_compose_cmd \
    logs \
    -f \
    --tail="${line_count_per_service}" \
    "${extra_compose_args[@]}"
}

main "${@}"
