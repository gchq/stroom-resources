#!/usr/bin/env bash

cmd_help_msg="Restarts the specified service or the whole stack if no service name is supplied.\nThe services will be shutdown in a graceful order"

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

do_restart() {
  if [ "$#" -eq 1 ]; then
    local -r service_name="$1"
    if is_service_in_stack "${service_name}"; then
      stop_service_if_in_stack "${service_name}"
      echo
      start_stack "${service_name}"
    else
      die "${RED}Error${NC}:" \
        "${BLUE}${service_name}${NC} is not part of this stack"
    fi
  else
    stop_stack
    echo
    start_stack
  fi
}

main() {
  # leading colon means silent error reporting by getopts
  while getopts ":hm" arg; do
    case $arg in
      h )  
        show_default_service_usage "${cmd_help_msg}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  if [ "$#" -gt 1 ]; then
    echo -e "${RED}Error${NC}: Invalid arguments, only one service name can be supplied" >&2
    show_default_service_usage "${cmd_help_msg}"
    exit 1
  fi

  setup_echo_colours

  do_restart "$@"

  wait_for_service_to_start

  # Stroom is now up or we have given up waiting so check the health
  check_overall_health

  # Display the banner, URLs and login details
  display_stack_info
}

main "$@"
