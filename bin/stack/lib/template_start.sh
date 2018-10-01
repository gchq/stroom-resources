#!/usr/bin/env bash
#
# shellcheck disable=SC2034
# shellcheck disable=SC1090
#
# Starts the stack, using the configuration defined in the .env file.

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/network_utils.sh
source "$DIR"/lib/shell_utils.sh

readonly HOST_IP=$(determine_host_address)

setup_echo_colours
echo -e "Using IP: ${BLUE}${HOST_IP}${NC}"

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

docker-compose -f "$DIR"/config/<STACK_NAME>.yml up -d
