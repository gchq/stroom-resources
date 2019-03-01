#!/usr/bin/env bash

cmd_help_msg="Stops the specified service or the whole stack if no service name is supplied."

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
    if is_service_in_stack "${service_name}"; then
      stop_service_if_in_stack "${service_name}"
    else
      die "${RED}Error${NC}:" \
        "${BLUE}${service_name}${NC} is not part of this stack"
    fi
  else
    stop_stack
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

  do_stop "$@"

  echo
  echo -e "${GREEN}Done${NC}"
}

main "$@"
