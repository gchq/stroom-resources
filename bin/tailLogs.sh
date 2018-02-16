#!/bin/bash

#exit script on any errors
set -e

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

#Check script arguments
if [ "$#" -eq 0 ] || ! [ -f "$1" ]; then
  echo -e "${RED}ERROR - Invalid arguments${NC}" >&2
  echo -e "${GREEN}Usage: $0 dockerComposeYmlFile optionalExtraArgsForDockerLogsCmd${NC}" >&2
  echo "E.g: $0 compose/everything.yml" >&2
  echo "E.g: $0 compose/everything.yml --tail 10" >&2
  echo 
  echo -e "${BLUE}Possible compose files:${NC}" >&2
  ls -1 ./compose/*.yml
  exit 1
fi

ymlFile=$1

#args from 2 onwards are extra docker args
extraDockerArgs="${*:2}"


echo -e "Using extra arguments for the docker-compose logs command [${GREEN}${extraDockerArgs}${NC}]"

projectName=$(basename ${ymlFile} | sed 's/\.yml$//')
echo "Project: ${projectName}"

docker-compose -f ${ymlFile} -p ${projectName} logs -f --timestamps --tail="all" --no-color ${extraDockerArgs} 2>/dev/null | lnav -q
