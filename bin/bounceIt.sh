#!/bin/bash

#exit the script on any error
set -e

LOCAL_HOST_NAMES="kafka hbase"

#Default docker tags if xxxx_TAG not set in environment variables
DEFAULT_STROOM_TAG="master-SNAPSHOT"
DEFAULT_STROOM_STATS_TAG="master-SNAPSHOT"

#Colour constants
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

DOCKER_TAGS_URL_PREFIX="from ${BLUE}https://hub.docker.com/r/gchq/"
DOCKER_TAGS_URL_SUFFIX="/tags/${NC}"

if [ "$#" -eq 0 ] || ! [ -f "$1" ]; then
  echo -e "${RED}Usage: $0 dockerComposeYmlFile optionalStroomDockerTag${NC}" >&2
  echo "E.g: $0 compose/everything.yml" >&2
  echo "E.g: $0 compose/everything.yml --build" >&2
  echo 
  echo -e "${BLUE}Possible compose files:${NC}" >&2
  ls -1 ./compose/*.yml
  exit 1
fi

ymlFile=$1

#check if the yml file contains any Docker tag variables, i.e. *_TAG
if grep -q "_TAG" $ymlFile; then
    echo
    echo "The following Docker tags will be used for this compose file:"
    #scan the yml file for any docker tag variables and then display their current
    #value (or a default) to the user for confirmation
    for tag in $(grep "_TAG" $ymlFile | sed -E 's/.*\$\{(.*)}.*/\1/g'); do 
        if [ "$tag" = "STROOM_TAG" ]; then
            url="${DOCKER_TAGS_URL_PREFIX}stroom${DOCKER_TAGS_URL_SUFFIX}"
            echo -e "Using STROOM_TAG =       ${GREEN}${STROOM_TAG:=${DEFAULT_STROOM_TAG}}${NC}\t$url"
            export STROOM_TAG

        elif [ "$tag" = "STROOM_STATS_TAG" ]; then
            url="${DOCKER_TAGS_URL_PREFIX}stroom-stats${DOCKER_TAGS_URL_SUFFIX}"
            echo -e "Using STROOM_STATS_TAG = ${GREEN}${STROOM_STATS_TAG:=${DEFAULT_STROOM_STATS_TAG}}${NC}\t$url"
            export STROOM_STATS_TAG
        fi
    done

    echo "Docker tags can be changed in a similar way to:"
    echo -e "  ${RED}export STROOM_TAG=\"master-SNAPSHOT\"${NC}"
    echo
    read -rsp $'Press space to continue, or ctrl-c to exit...\n' -n1 keyPressed

    if [ "$keyPressed" = '' ]; then
        echo
    else
        echo "Exiting"
        exit 0
    fi

    #read -r -p "Do you wish to continue? [y/N] " response
    #if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        #exit 0
    #fi
fi

#args from 2 onwards are extra docker args
extraDockerArgs="${*:2}"

projectName=`basename $ymlFile | sed 's/\.yml$//'`

isHostMissing=""

#Some of the docker containers required entires in your local hosts file to
#work correctly. This code checks they are all there
for host in $LOCAL_HOST_NAMES; do
    if [ $(cat /etc/hosts | grep -e "127\.0\.0\.1\s*$host" | wc -l) -eq 0 ]; then 
        echo -e "${RED}ERROR${NC} - /etc/hosts is missing an entry for \"127.0.0.1 $host\""
        isHostMissing=true
        echo "Add the following line to /etc/hosts:"
        echo "${GREEN}127.0.0.1 $host${NC}"
        echo
    fi
done

if [ $isHostMissing ]; then
    echo "Quting!"
    exit 1
fi


#Ensure we have the latest image of stroom from dockerhub
#Needed for floating tags like *-SNAPSHOT or v6
if grep -q "stroom:" $ymlFile ; then
    echo "Compose file contains stroom, checking for any updates to the stroom image on dockerhub"
    docker-compose -f "$ymlFile" -p "$projectName" pull stroom
fi
if grep -q "stroom-stats:" $ymlFile ; then
    echo "Compose file contains stroom-stats, checking for any updates to the stroom-stats image on dockerhub"
    docker-compose -f $ymlFile -p $projectName pull stroom-stats
fi

echo 
echo "Bouncing project $projectName with using $ymlFile with additional arguments for 'docker-compose up' [${extraDockerArgs}]"
echo "This will restart any existing containers (preserving their state), or create any containers that do not exist."
echo "If you want to rebuild images from your own dockerfiles pass the '--build' argument"
echo 

#pass any additional arguments after the yml filename direct to docker-compose
docker-compose -f $ymlFile -p $projectName stop && docker-compose -f $ymlFile -p $projectName up $extraDockerArgs
