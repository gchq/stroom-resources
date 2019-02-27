#!/usr/bin/env bash

# Restarts the stack

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/network_utils.sh
source "$DIR"/lib/shell_utils.sh
source "$DIR"/lib/stroom_utils.sh

setup_echo_colours

# This is needed in the docker compose yaml
readonly HOST_IP=$(determine_host_address)

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>" 

do_restart() {
  if [ "$#" -eq 1 ]; then
    local -r service_name="$1"
    stop_service_if_in_stack "${service_name}"
    echo
    start_stack "${service_name}"
  else
    stop_stack
    echo
    start_stack
  fi
}

main() {
  # leading colon means silent error reporting by getopts
  while getopts ":m" arg; do
    case $arg in
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  setup_echo_colours

  do_restart "$@"

  wait_for_service_to_start

  # Stroom is now up or we have given up waiting so check the health
  check_overall_health

  # Display the banner, URLs and login details
  display_stack_info
}

main "$@"
