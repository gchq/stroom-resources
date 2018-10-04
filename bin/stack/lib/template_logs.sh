#!/usr/bin/env bash
#
# Shows the stacks logs

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker-compose -f "$DIR"/config/<STACK_NAME>.yml logs -f --tail="5" "$@"
