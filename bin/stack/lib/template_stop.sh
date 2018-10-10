#!/usr/bin/env bash
#
# Stops the stack

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh
setup_echo_colours

echo -e "${GREEN}Stopping the docker containers${NC}"
echo

docker-compose -f "$DIR"/config/<STACK_NAME>.yml stop
