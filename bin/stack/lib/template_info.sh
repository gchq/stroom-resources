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
cmd_help_msg="Displays information about the stack"

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}"/lib/network_utils.sh
source "${DIR}"/lib/shell_utils.sh
source "${DIR}"/lib/stroom_utils.sh
source "${DIR}"/lib/constants.sh

main() {
  # leading colon means silent error reporting by getopts
  while getopts ":mh" arg; do
    case $arg in
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
      h )  
        show_default_usage "${cmd_help_args}" "${cmd_help_msg}"
        exit 0
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  setup_echo_colours

  # Read the file containing all the env var exports to make them
  # available to docker-compose
  source "${DIR}"/config/<STACK_NAME>.env

  # shellcheck disable=SC2034
  STACK_NAME="<STACK_NAME>" 

  # Don't exit if any fail
  check_prerequisites || true

  display_stack_info
}

main "${@}"

# Reset trap status
trap - EXIT ERR
