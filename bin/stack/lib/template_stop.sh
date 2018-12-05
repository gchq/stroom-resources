#!/usr/bin/env bash
#
# Stops the stack gracefully

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh
source "$DIR"/lib/stroom_utils.sh
setup_echo_colours

main() {
    stop_stack "<STACK_NAME>"

    echo
    echo -e "${GREEN}Done${NC}"
}

main
