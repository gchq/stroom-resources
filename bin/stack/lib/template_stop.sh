#!/usr/bin/env bash

cmd_help_msg="Stops the specified service(s) or the whole stack if no service names are supplied."

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
{
  source "$DIR"/lib/shell_utils.sh
  source "$DIR"/lib/stroom_utils.sh
}

setup_echo_colours

# shellcheck disable=SC2034
STACK_NAME="<STACK_NAME>"

do_stop() {
  if [ "$#" -gt 0 ]; then
    for service_name in "$@"; do
      if ! is_service_in_stack "${service_name}"; then
        die "${RED}Error${NC}:" \
          "${BLUE}${service_name}${NC} is not part of this stack"
      fi
    done
    stop_services_if_in_stack "$@"
  else
    stop_stack
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

  setup_echo_colours

  do_stop "$@"

  echo
  echo -e "${GREEN}Done${NC}"
}

main "$@"
