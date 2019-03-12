#!/usr/bin/env bash

cmd_help_args=""
cmd_help_msg="Pulls all docker images from the remote repository"

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
{
  source "$DIR"/lib/network_utils.sh
  source "$DIR"/lib/shell_utils.sh
  source "$DIR"/lib/stroom_utils.sh
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

  local error_count=0

  local images
  images="$("${DIR}/show_config.sh" | grep -oP "(?<=image:)\s\S+")"

   while read -r image; do
    # remove any leading whitespace
    image="${image#"${image%%[![:space:]]*}"}"
    echo 
    echo -e "${GREEN}Pulling image ${BLUE}${image}${GREEN} from the remote repository${NC}"
    docker image pull "${image}" \
      || { \
        echo -e "${RED}Error${GREEN}: Unable to pull ${BLUE}${image}${GREEN}" \
          "from the remote repository${NC}" && error_count=$(( error_count + 1 )) 
      }
  done <<< "${images}"

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

