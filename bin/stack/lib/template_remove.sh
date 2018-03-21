#!/usr/bin/env bash
#
# Removes the stack from the host. All containers are stopped and removed. So are their volumes!

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker-compose -f "$DIR"/config/<STACK_NAME>.yml down -v