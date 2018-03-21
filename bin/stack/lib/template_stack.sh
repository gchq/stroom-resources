#!/usr/bin/env bash
#
# A single script interface to manage the stack

# source lib/network.sh
# host_ip=$(determine_host_address)

# source lib/shell.sh
# setup_echo_colours

# source config/core.env

NO_ARGUMENT_MESSAGE="Please supply an argument: either ${YELLOW}start${NC}, ${YELLOW}stop${NC}, ${YELLOW}restart${NC}, ${YELLOW}logs${NC}, ${YELLOW}status${NC}, ${YELLOW}ctop${NC}, or ${YELLOW}remove${NC}."
# Check script's params
if [ $# -ne 1 ]; then
    err $NO_ARGUMENT_MESSAGE
    exit 1
fi

case $1 in
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
    ctop)
        source ctop.sh
    ;;
    remove)
        source remove.sh
    ;;
esac