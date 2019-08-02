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

CMD_HELP_MSG="Restarts the specified service(s) or the whole stack if no service names are supplied.\nThe services will be shutdown in a graceful order"
Q_OPTION_TEXT="  -q   Quiet start. Don't wait for health checks and don't display info."

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
source "$DIR"/config/stroom_core.env

# shellcheck disable=SC2034
STACK_NAME="stroom_core" 

do_restart() {
  if [ "$#" -gt 0 ]; then
    for service_name in "$@"; do
      if ! is_service_in_stack "${service_name}"; then
        die "${RED}Error${NC}:" \
          "${BLUE}${service_name}${NC} is not part of this stack"
      fi
    done
    stop_services_if_in_stack "$@"
    echo
    start_stack "$@"
  else
    stop_stack_gracefully
    echo
    start_stack
  fi
}

main() {
  local wait_for_health_checks=true
  # leading colon means silent error reporting by getopts
  while getopts ":hmq" arg; do
    case $arg in
      h )  
        show_default_services_usage "${CMD_HELP_MSG}" "${Q_OPTION_TEXT}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
      q )  
        wait_for_health_checks=false
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  setup_echo_colours

  do_restart "$@"

  if [ "${wait_for_health_checks}" = true ]; then
    wait_for_service_to_start

    # Stroom is now up or we have given up waiting so check the health
    check_overall_health

    # Display the banner, URLs and login details
    display_stack_info
  fi
}

main "$@"
