#!/usr/bin/env bash
#
# Restarts the stack

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/network_utils.sh
HOST_IP=$(determine_host_address)
source "$DIR"/config/core.env


docker-compose -f "$DIR"/config/<STACK_NAME>.yml restart