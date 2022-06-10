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

cmd_help_args="COMMAND [COMMAND ARGS...]"
cmd_help_msg="Runs a command a stroom command. See https://gchq.github.io/stroom-docs/latest/docs/user-guide/tools/command-line/."

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
DIR=
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1091
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
# shellcheck disable=SC1091
source "$DIR"/config/<STACK_NAME>.env

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>" 

check_installed_binaries() {
  # The version numbers mentioned here are mostly governed by the docker
  # compose syntax version that we use in the yml files, currently 2.4, see
  # https://docs.docker.com/compose/compose-file/compose-versioning/

  if ! command -v docker 1>/dev/null; then 
    echo -e "${RED}ERROR${NC}: Docker CE is not installed!"
    echo -e "See ${BLUE}https://docs.docker.com/install/#supported-platforms${NC}" \
      "for details on how to install it"
    echo -e "Version ${BLUE}17.12.0${NC} or higher is required"
    exit 1
  fi

  if ! command -v docker-compose 1>/dev/null; then 
    echo -e "${RED}ERROR${NC}: Docker Compose is not installed!"
    echo -e "See ${BLUE}https://docs.docker.com/compose/install/${NC} for" \
      "details on how to install it"
    echo -e "Version ${BLUE}1.23.1${NC} or higher is required"
    exit 1
  fi
}

main() {
  # leading colon means silent error reporting by getopts
  while getopts "hm" arg; do
    # shellcheck disable=SC2220
    case $arg in
      h )  
        show_default_usage "${cmd_help_args}" "${cmd_help_msg}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  # Remaining args are our command and its args
  local dropwiz_command_and_args=( "$@" )

  if [[ $# -lt 1 ]]; then
    echo -e "${RED}Error${NC}: No command provided"
    show_default_usage "${cmd_help_args}" "${cmd_help_msg}"
    exit 1
  fi

  setup_echo_colours

  if ! is_service_in_stack "stroom"; then
    die "${RED}Error${NC}: Service ${BLUE}stroom${NC} is not in the stack."
  fi

  check_installed_binaries

  run_dropwiz_command "${dropwiz_command_and_args[@]}"

  echo -e "${GREEN}Execution of command" \
    "[${BLUE}${dropwiz_command_and_args[*]}${GREEN}] complete${NC}"
}

main "$@"
