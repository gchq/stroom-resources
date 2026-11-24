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

CMD_HELP_MSG="Kills the specified service(s) or the whole stack if no service names are supplied."

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

main() {
  local is_fast_stop=false
  # leading colon means silent error reporting by getopts
  while getopts ":hmf" arg; do
    case $arg in
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

  validate_services "$@"
  kill_stack "$@"

  echo
  echo -e "${GREEN}Done${NC}"
}

main "$@"
