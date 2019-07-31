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

CMD_HELP_MSG="Sets the list of services that will be used on this node."

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
{
  source "$DIR"/lib/network_utils.sh
  source "$DIR"/lib/shell_utils.sh
  source "$DIR"/lib/stroom_utils.sh
  source "$DIR"/lib/constants.sh
}

get_all_services_in_stack() {
  cut -d "|" -f 1 < "${DIR}/${ALL_SERVICES_FILENAME}" 
}

is_service_in_all_services() {
  local -r service_name="$1"

  # return true if service_name is in the file
  # file is serviceName|fullyQualifiedDockerTag
  if grep -q "^${service_name}|" "${ALL_SERVICES_FILE}"; then
    return 0;
  else
    return 1;
  fi
}

show_all_services_usage_part() {
  # shellcheck disable=SC2002
  if [ -f "${DIR}/${ALL_SERVICES_FILENAME}" ] \
    && [ "$(cat "${DIR}/${ALL_SERVICES_FILENAME}" | wc -l)" -gt 0 ]; then

    echo -e "Valid SERVICE values:"
    while read -r service; do
      echo -e "  ${service}"
    done <<< "$( get_all_services_in_stack )"
  fi
}

show_all_services_usage() {
  show_default_usage "[SERVICE]..." "$@"
  show_all_services_usage_part
}

validate_services() {
  for service_name in "$@"; do
    if ! is_service_in_all_services "${service_name}"; then
      die "${RED}Error${NC}:" \
        "${BLUE}${service_name}${NC} is not a valid service, use the -h argument to see the list of valid services"
    fi
  done
}

main() {
  STACK_SERVICES_FILE="${DIR}/${STACK_SERVICES_FILENAME}"
  ALL_SERVICES_FILE="${DIR}/${ALL_SERVICES_FILENAME}"

  if [ ! -f "${STACK_SERVICES_FILE}" ]; then
    die "${RED}Error${NC}: Active services file ${BLUE}${STACK_SERVICES_FILE}${NC}" \
      "can't be found."
  fi

  if [ ! -f "${ALL_SERVICES_FILE}" ]; then
    die "${RED}Error${NC}: All services file ${BLUE}${ALL_SERVICES_FILE}${NC}" \
      "can't be found."
  fi

  # leading colon means silent error reporting by getopts
  while getopts ":hmq" arg; do
    case $arg in
      h )  
        show_all_services_usage "${CMD_HELP_MSG}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  if [ "$#" -eq 0 ]; then
      die "${RED}Error${NC}: Must supply at least one service"
  fi

  for requested_service in "${@}"; do
    if ! is_service_in_all_services "${requested_service}"; then
      die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not" \
        "in the list of all services for this stack."
    fi
  done

  # clear the list of active services
  > "${STACK_SERVICES_FILE}"
  for requested_service in "${@}"; do
    # Add the line from all services for this service to the stack services list
    grep "^${requested_service}|" \
      < "${ALL_SERVICES_FILE}" \
      >> "${STACK_SERVICES_FILE}"
  done

  echo -e "${GREEN}Setting active services for the stack${NC}"

  display_active_stack_services

  echo -e "${GREEN}Done${NC}"
}

main "$@"
