#!/usr/bin/env bash

cmd_help_msg="Starts the specified services or the whole stack if no service name is supplied."

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
{
  source "$DIR"/lib/network_utils.sh
  source "$DIR"/lib/shell_utils.sh
  source "$DIR"/lib/stroom_utils.sh
}

# This line MUST be before we source the env file, as HOST_IP may be set
# in the env file and thus needs to override the HOST_IP determined here.
# shellcheck disable=SC2034
HOST_IP=$(determine_host_address)

# Read the file containing all the env var exports to make them
# available to docker-compose
# shellcheck disable=SC1090
source "$DIR"/config/<STACK_NAME>.env

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>" 

check_installed_binaries() {
  # The version numbers mentioned here are mostly governed by the docker compose syntax version that 
  # we use in the yml files, currently 2.4, see https://docs.docker.com/compose/compose-file/compose-versioning/

  if ! command -v docker 1>/dev/null; then 
    echo -e "${RED}ERROR${NC}: Docker CE is not installed!"
    echo -e "See ${BLUE}https://docs.docker.com/install/#supported-platforms${NC} for details on how to install it"
    echo -e "Version ${BLUE}17.12.0${NC} or higher is required"
    exit 1
  fi

  if ! command -v docker-compose 1>/dev/null; then 
    echo -e "${RED}ERROR${NC}: Docker Compose is not installed!"
    echo -e "See ${BLUE}https://docs.docker.com/compose/install/${NC} for details on how to install it"
    echo -e "Version ${BLUE}1.23.1${NC} or higher is required"
    exit 1
  fi
}

main() {
  # leading colon means silent error reporting by getopts
  while getopts ":hm" arg; do
    case $arg in
      h )  
        show_default_services_usage "${cmd_help_msg}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  for requested_service in "${@}"; do
    if ! is_service_in_stack "${requested_service}"; then
      die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not in the stack."
    fi
  done

  setup_echo_colours

  check_installed_binaries

  start_stack "$@"

  wait_for_service_to_start

  # Stroom is now up or we have given up waiting so check the health
  check_overall_health

  # Display the banner, URLs and login details
  display_stack_info
}

main "$@"
