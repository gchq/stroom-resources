#!/usr/bin/env bash

cmd_help_args=""
cmd_help_msg="Displays information about the stack"

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}"/lib/network_utils.sh
source "${DIR}"/lib/shell_utils.sh
source "${DIR}"/lib/stroom_utils.sh

#readonly HOST_IP=$(determine_host_address)

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

  display_stack_info
}

main "${@}"
