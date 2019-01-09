#!/bin/bash

# 'xargs -r' doesn't work on MacOS, see 
# https://stackoverflow.com/questions/17402345/ignore-empty-results-for-xargs-in-mac-os-x
# Suggest you use GNU xargs from 'brew install findutils'

#Shell Colour constants for use in 'echo -e'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Doesn't touch auth-db to keep any password changes intact

echo -e "${GREEN}Stopping container ${BLUE}stroom-all-dbs${NC}"
docker stop stroom-all-dbs

echo -e "${GREEN}Removing container ${BLUE}stroom-all-dbs${NC}"
docker rm stroom-all-dbs

echo -e "${GREEN}Removing volume ${BLUE}everything_stroom-all-dbs_data${NC}"
docker volume rm everything_stroom-all-dbs_data

echo -e "${GREEN}Removing volume ${BLUE}everything_stroom-all-dbs_logs${NC}"
docker volume rm everything_stroom-all-dbs_logs

echo -e "${GREEN}Creating container ${BLUE}stroom-all-dbs${NC}"
./bounceIt.sh create -y -i stroom-all-dbs

echo -e "${GREEN}Starting container ${BLUE}stroom-all-dbs${NC}"
./bounceIt.sh start -y -i stroom-all-dbs
