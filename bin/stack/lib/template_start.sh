#!/usr/bin/env bash
#
# shellcheck disable=SC2034
# shellcheck disable=SC1090
#
# Starts the stack, using the configuration defined in the .env file.

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/network_utils.sh
source "$DIR"/lib/shell_utils.sh

readonly HOST_IP=$(determine_host_address)

setup_echo_colours

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

# These lines may help in debugging the config that is passed to the containers
#env
#docker-compose -f "$DIR"/config/stroom_core.yml config

echo -e "${GREEN}Creating and starting the docker containers and volumes${NC}"
#echo -e "${GREEN}Using IP address ${BLUE}${HOST_IP}${NC}"
echo

docker-compose --project-name <STACK_NAME> -f "$DIR"/config/<STACK_NAME>.yml up -d

echo
echo -e "${GREEN}Waiting for stroom to complete its start up.${NC}"
echo -e "${DGREY}Stroom has to build its database tables when started for the first time,${NC}"
echo -e "${DGREY}so this may take a minute or so. Subsequent starts will be quicker.${NC}"

wait_for_200_response "http://localhost:${STROOM_ADMIN_PORT}/stroomAdmin"

# Stroom is now up or we have given up waiting so check the health
./health.sh

# Display the banner, URLs and login details
./info.sh

