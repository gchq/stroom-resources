#!/usr/bin/env bash
#
# Stops the stack gracefully

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh
source "$DIR"/lib/stroom_utils.sh
setup_echo_colours

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>"

do_stop() {
  if [ "$#" -eq 1 ]; then
    local -r service_name="$1"
    stop_service_if_in_stack "${service_name}"
  else
    stop_stack
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

  do_stop "$@"

  echo
  echo -e "${GREEN}Done${NC}"
}

main "$@"
