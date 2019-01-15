#!/usr/bin/env bash
#
# A single script interface to manage the stack

setup_echo_colours() {
  # shellcheck disable=SC2034
  if [ "${MONOCHROME}" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BLUE2=''
    NC='' # No Colour
  else 
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    BLUE2='\033[1;34m'
    NC='\033[0m' # No Colour
  fi
}

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

NO_ARGUMENT_MESSAGE="Please supply an argument: either ${YELLOW}start${NC}, ${YELLOW}stop${NC}, ${YELLOW}restart${NC}, ${YELLOW}logs${NC}, ${YELLOW}status${NC}, ${YELLOW}health${NC}, ${YELLOW}info${NC} or ${YELLOW}remove${NC}."
# Check script's params
if [ $# -ne 1 ]; then
    err "${NO_ARGUMENT_MESSAGE}"
    exit 1
fi

case $1 in
    config)
        source config.sh
    ;;
    start)
        source start.sh
    ;;
    stop)
        source stop.sh
    ;;
    restart)
        source restart.sh
    ;;
    logs)
        source logs.sh
    ;;
    status)
        source status.sh
    ;;
    remove)
        source remove.sh
    ;;
    health)
        source health.sh
    ;;
    info)
        source info.sh
    ;;
esac
