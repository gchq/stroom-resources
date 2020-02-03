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
cmd_help_msg="Removes the complete stack from the host.\nAll containers are stopped and removed. So are their volumes!\nAll data (content, events, indexes, etc.) will be lost!"
cmd_help_options="  -y   Do not prompt for confirmation, e.g. when run from a script"

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}"/lib/shell_utils.sh
source "${DIR}"/lib/stroom_utils.sh
source "${DIR}"/lib/constants.sh

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>" 

main() {
  local requireConfirmation=true

  local optspec=":mhy"
  while getopts "$optspec" optchar; do
    case "${optchar}" in
      h )  
        show_default_usage "${cmd_help_args}" "${cmd_help_msg}" "${cmd_help_options}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
      y)
        requireConfirmation=false
        ;;
      *)
        echo -e "Error: Unknown argument: '-${OPTARG}'" >&2
        echo
        show_default_usage "${cmd_help_args}" "${cmd_help_msg}" "${cmd_help_options}"
        exit 1
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  setup_echo_colours

  if [ "$requireConfirmation" = true ]; then

    echo
    echo -e "${RED}WARNING:${NC} ${GREEN}This will remove all the Docker containers and volumes in the stack${NC}"
    echo -e "${GREEN}so all data (content, events, indexes, etc.) will be lost.${NC}"
    echo
    read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

    if [ "$keyPressed" = 'y' ] || [ "$keyPressed" = 'Y' ]; then
      echo
      echo -e "${RED}WARNING:${NC} ${GREEN}You are about to completely remove the stack including ALL data.${NC}"
      echo -e "${GREEN}Are you sure?${NC}"
      echo
      read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

      if [ "$keyPressed" = 'y' ] || [ "$keyPressed" = 'Y' ]; then
        echo
      else
        echo
        echo "Exiting"
        exit 0
      fi
    else
      echo
      echo "Exiting"
      exit 0
    fi
  fi

  # We don't really care about shutdown order here as we are destroying the stack
  echo -e "${GREEN}Stopping and removing the Docker containers and volumes${NC}"
  echo

  # shellcheck disable=SC2094
  run_docker_compose_cmd \
    down \
    -v
}

main "$@"
