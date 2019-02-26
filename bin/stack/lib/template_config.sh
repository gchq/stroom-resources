#!/usr/bin/env bash

# Displays the effective config for the stack with all environment variables
# applied.

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/network_utils.sh
source "$DIR"/lib/shell_utils.sh

readonly HOST_IP=$(determine_host_address)

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

echo -e "Using IP: ${BLUE}${HOST_IP}${NC}"

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

#shellcheck disable=SC2094
docker-compose \
  --project-name <STACK_NAME> \
  -f "$DIR"/config/<STACK_NAME>.yml \
  config
