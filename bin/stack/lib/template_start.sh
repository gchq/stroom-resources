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

# Stroom is now up or we have given up waiting so print the banner and links

# see if the terminal supports colors...
no_of_colours=$(tput colors)

if test -n "$no_of_colours" && test $no_of_colours -eq 256; then
    # 256 colours so print the stroom banner in dirty orange
    echo -en "\e[38;5;202m"
else
    # No 256 colour support so fall back to blue
    echo -en "${BLUE}"
fi
cat ${DIR}/lib/banner.txt
echo -en "${NC}"

echo
echo -e "Please use the following URLs to access stroom"
echo
echo -e "  ${GREEN}stroom UI${NC}:${BLUE}             http://localhost/stroom${NC}"
echo
echo -e "  (Login with the default username/password: ${BLUE}admin${NC}/${BLUE}admin${NC})"
echo
echo -e "  ${GREEN}stroom (admin)${NC}:${BLUE}        http://localhost:${STROOM_ADMIN_PORT}/stroomAdmin${NC}"

if [[ ! -z ${STROOM_STATS_SERVICE_ADMIN_PORT} ]]; then
    echo -e "  ${GREEN}stroom-stats${NC}:${BLUE}  http://localhost:${STROOM_STATS_SERVICE_ADMIN_PORT}/statsAdmin${NC}"
fi

echo -e "  ${GREEN}stroom-proxy (admin)${NC}:${BLUE}  http://localhost:${STROOM_PROXY_ADMIN_PORT}/proxyAdmin${NC}"
echo -e "  ${GREEN}stroom-auth (admin)${NC}:${BLUE}   http://localhost:${STROOM_AUTH_SERVICE_ADMIN_PORT}/authenticationServiceAdmin${NC}"
echo

