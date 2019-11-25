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

cmd_help_args=""
cmd_help_msg="Checks the running state of each service and checks the\nhealth of each application using its admin URL"
cmd_help_options="  -q   Quiet; do not write anything to standard output. Exit with a non-zero status if the stack is unhealthy."

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}"/lib/shell_utils.sh
source "${DIR}"/lib/stroom_utils.sh
source "${DIR}"/lib/constants.sh

main() {

  # leading colon means silent error reporting by getopts
  while getopts ":hmq" arg; do
    # shellcheck disable=SC2034
    case $arg in
      h )  
        show_default_usage "${cmd_help_args}" "${cmd_help_msg}" "${cmd_help_options}"
        exit 0
        ;;
      m )  
        MONOCHROME=true 
        ;;
      q )  
        QUIET_MODE=true 
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  if [ "${QUIET_MODE}" = false ]; then
    setup_echo_colours
  fi

  # Read the file containing all the env var exports so we can test
  # if certain port variables are set or not
  source "$DIR"/config/<STACK_NAME>.env

  # shellcheck disable=SC2034
  STACK_NAME="<STACK_NAME>"

  check_overall_health

  # return the unhealthy count so this script can be used in an automated way
  exit $?

}

main "${@}"

# Reset trap status
trap - EXIT ERR
