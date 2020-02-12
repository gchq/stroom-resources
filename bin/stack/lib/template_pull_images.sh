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
cmd_help_msg="Pulls all docker images from the remote repository"

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

# Read the file containing all the env var exports to make them
# available to docker-compose
# shellcheck disable=SC1090
source "$DIR"/config/<STACK_NAME>.env

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
  # shellcheck disable=SC1090
  source "$DIR"/config/<STACK_NAME>.env

  # shellcheck disable=SC2034
  STACK_NAME="<STACK_NAME>" 

  local error_count=0

  # Attempt to pull the docker image for each service in the active
  # services file
  while read -r image; do
    if docker inspect "${image}" 1>/dev/null 2>&1 \
      && [[ ! "${image}" =~ :.*(LATEST|SNAPSHOT|latest)$ ]]; then
      # We already have it and it isn't a floating tag
      echo 
      echo -e "${GREEN}Found image ${BLUE}${image}${GREEN} locally${NC}"
    else
      echo 
      echo -e "${GREEN}Pulling image ${BLUE}${image}${GREEN} from the remote repository${NC}"
      docker image pull "${image}" \
        || { \
          echo -e "${RED}Error${GREEN}: Unable to pull ${BLUE}${image}${GREEN}" \
            "from the remote repository${NC}" && error_count=$(( error_count + 1 )) 
        }
    fi
  done <<< "$( get_active_images_in_stack )"

  echo
  if [ "${error_count}" -eq 0 ]; then
    echo -e "${GREEN}Done${NC}"
  elif [ "${error_count}" -eq 1 ]; then
    echo -e "${RED}Done with ${error_count} error${NC}"
  else
    echo -e "${RED}Done with ${error_count} errors${NC}"
  fi
}

main "${@}"

