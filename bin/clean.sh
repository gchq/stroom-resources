#!/bin/bash

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
LGREY='\e[37m'
DGREY='\e[90m'
NC='\033[0m' # No Color

CONTAINERS=$(docker ps -a -q)
if [ ${#CONTAINERS} -ge 1 ]; then

    echo -e "${GREEN}Stopping and removing the following containers:${NC}"

    echo $CONTAINERS
    docker stop $CONTAINERS
    docker rm -v $CONTAINERS
else
    echo -e "${GREEN}There are no existing containers${NC}"
fi

# remove exited containers:
echo -e "${GREEN}Removing exited containers and their volumes${NC}"
docker ps --filter status=dead --filter status=exited -aq | xargs -r docker rm -v

# remove unused images:
echo -e "${GREEN}Removing unused images${NC}"
docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs -r docker rmi

# remove unused volumes:
echo -e "${GREEN}Removing unused volumes${NC}"
docker volume ls -qf dangling=true | xargs -r docker volume rm
