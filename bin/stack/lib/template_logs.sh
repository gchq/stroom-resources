#!/usr/bin/env bash
#
# Shows the stacks logs

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh

setup_echo_colours

LINE_COUNT_PER_SERVICE=5

echo -e "${GREEN}Tailing the logs from the last ${LINE_COUNT_PER_SERVICE} entries onwards${NC}"

docker-compose --project-name <STACK_NAME> -f "$DIR"/config/<STACK_NAME>.yml logs -f --tail="${LINE_COUNT_PER_SERVICE}" "$@"
