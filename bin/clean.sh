#!/bin/bash

setup_echo_colours() {
  # Exit the script on any error
  set -e

  # shellcheck disable=SC2034
  if [ "${MONOCHROME}" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BLUE2=''
    DGREY=''
    NC='' # No Colour
  else 
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    BLUE2='\033[1;34m'
    DGREY='\e[90m'
    NC='\033[0m' # No Colour
  fi
}

# These are the names of the only containers that will get deleted
STROOM_CONTAINER_NAMES=( \
  "nginx" \
  "stroom" \
  "stroom-proxy" \
  "stroom-all-dbs" \
  "stroom-log-sender" \
  "zookeeper" \
  "kafka" \
  "elasticsearch")

main() {
  setup_echo_colours

  # Build the docker filter args so we don't delete other containers
  filter_args=( )
  echo -e "${GREEN}Cleaning the following containers:${NC}"
  for name in "${STROOM_CONTAINER_NAMES[@]}"; do
    echo "${name}"
    filter_args+=( "--filter" "name=${name}" )
  done

  # Find all the containers to delete
  CONTAINERS=$(docker ps -a -q "${filter_args[@]}" )

  container_args=( )
  for container in ${CONTAINERS}; do
    #echo "container: ${container}"
    container_args+=( "${container}" )
  done

  if [ ${#container_args} -ge 1 ]; then
    echo -e "${GREEN}Stopping containers:${NC}"
    docker stop "${container_args[@]}"

    echo -e "${GREEN}Removing containers:${NC}"
    docker rm -v "${container_args[@]}"
  else
    echo -e "${GREEN}There are no existing containers${NC}"
  fi

  # remove exited containers:
  # Not sure this really adds anything
  echo -e "${GREEN}Removing exited containers and their volumes${NC}"
  docker \
    ps \
    --filter status=dead \
    --filter status=exited \
    "${filter_args[@]}" \
    -aq \
    | xargs -r docker rm -v

  # remove unused images:
  echo -e "${GREEN}Removing unused images${NC}"
  docker images --no-trunc \
    | grep '<none>' \
    | awk '{ print $3 }' \
    | xargs -r docker rmi

  # remove unused volumes:
  # We want to keep builder-home-dir-vol as that contains all the mvn/node/gradle
  # stuff that makes the dockerised build quicker
  echo -e "${GREEN}Removing unused volumes apart from ${BLUE}builder-home-dir-vol${NC}"
  docker volume ls -qf dangling=true \
    | grep -v builder-home-dir-vol \
    | xargs -r docker volume rm
}

main "$@"
