#!/usr/bin/env bash
#
# TODO

# Exit the script on any error
set -e

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
LGREY='\e[37m'
DGREY='\e[90m'
NC='\033[0m' # No Color

err() {
  echo -e "$@" >&2
}

NO_ARGUMENT_MESSAGE="Please supply an argument: either ${YELLOW}start${NC}, ${YELLOW}stop${NC}, ${YELLOW}restart${NC}, ${YELLOW}logs${NC}, ${YELLOW}status${NC}, ${YELLOW}ctop${NC}, or ${YELLOW}remove${NC}."
# Check script's params
if [ $# -ne 1 ]; then
    err $NO_ARGUMENT_MESSAGE
    exit 1
fi

source core.env

case $1 in
    start)
        docker-compose -f <STACK_NAME>.yml up -d
    ;;
    stop)
        docker-compose -f <STACK_NAME>.yml stop
    ;;
    restart)
        docker-compose -f <STACK_NAME>.yml restart
    ;;
    logs)
        docker-compose -f <STACK_NAME>.yml logs -f
    ;;
    status)
        docker ps --all --filter "label=stack_name=<STACK_NAME>" --format  "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.ID}}"
    ;;
    ctop)
        docker attach ctop
    ;;
    remove)
        docker-compose -f <STACK_NAME>.yml down -v
    ;;
esac