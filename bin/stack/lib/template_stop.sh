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

CMD_HELP_MSG="Stops the specified service(s) or the whole stack if no service names are supplied."
F_OPTION_TEXT="  -f   Fast stop. Stop all containers at the same time. Not a graceful shutdown."

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
{
  source "${DIR}"/lib/shell_utils.sh
  source "${DIR}"/lib/stroom_utils.sh
  source "${DIR}"/lib/constants.sh
}

setup_echo_colours

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>"

validate_services

do_stop() {
  if [ "$#" -gt 0 ]; then
    validate_services "$@"
    stop_services_if_in_stack "$@"
  else
    stop_stack_gracefully
  fi
}

main() {
  local is_fast_stop=false
  # leading colon means silent error reporting by getopts
  while getopts ":hmf" arg; do
    case $arg in
      f )  
        is_fast_stop=true
        ;;
      h )  
        show_default_services_usage "${CMD_HELP_MSG}" "${F_OPTION_TEXT}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  setup_echo_colours

  if [ "${is_fast_stop}" = true ]; then
    validate_services "$@"
    stop_stack_quickly "$@"
  else
    do_stop "$@"
  fi

  echo
  echo -e "${GREEN}Done${NC}"
}

main "$@"

# Reset trap status
trap - EXIT ERR
