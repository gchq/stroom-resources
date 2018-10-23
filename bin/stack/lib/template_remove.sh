#!/usr/bin/env bash

# Removes the stack from the host. All containers are stopped and removed. So are their volumes!

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh
setup_echo_colours

    echo
    echo -e "${RED}WARNING:${NC} ${GREEN}This will remove all the Docker containers and volumes in the stack${NC}"
    echo -e "${GREEN}so all data (content, events, indexes, etc.) will be lost.${NC}"
    echo
    read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

    if [ "$keyPressed" = 'y' ] || [ "$keyPressed" = 'Y' ]; then
        echo
    else
        echo
        echo "Exiting"
        exit 0
    fi

echo -e "${GREEN}Stopping and removing the Docker containers and volumes${NC}"
echo

docker-compose --project-name <STACK_NAME> -f "$DIR"/config/<STACK_NAME>.yml down -v
