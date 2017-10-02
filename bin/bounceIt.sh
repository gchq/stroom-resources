#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Script to start up a docker compose yml configuration. The script will
# look for any variables of the form '${xxxxx_TAG}' in the compose file 
# and set the value of those variables according to the values found in 
# DEFAULT_TAGS_FILE
#
# If you want to add a new docker imaage that supports custom tags then
# you need to add code in here in three places, search below for 
# 'IMAGE SPECIFIC CODE'


#exit the script on any error
set -e

#List of hostnames that need to be added to /etc/hosts to resolve to 127.0.0.1
LOCAL_HOST_NAMES="kafka hbase"

#Default docker tags if xxxx_TAG not set in environment variables
#DEFAULT_STROOM_TAG="master-SNAPSHOT"
#DEFAULT_STROOM_STATS_TAG="master-SNAPSHOT"

#Location of the file used to define the docker tag variable values
DEFAULT_TAGS_FILE="${HOME}/.stroom/docker.tags"

#These are the default values for each docker tag variable 
#IMAGE SPECIFIC CODE
DEFAULT_TAGS="\
#comment lines are supported like this (no space before or after '#')
STROOM_TAG=master-SNAPSHOT
STROOM_STATS_TAG=master-SNAPSHOT"

#regex used to locate a docker tag variable in a docker-compose .yml file
TAG_VARIABLE_REGEX="\${.*_TAG}" 

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

DOCKER_TAGS_URL_PREFIX="from ${BLUE}https://hub.docker.com/r/gchq/"
DOCKER_TAGS_URL_SUFFIX="/tags/${NC}"

#Ensure we have a docker.tags file
if [ ! -f ${DEFAULT_TAGS_FILE} ]; then
    echo -e "Default docker tags file (${BLUE}${DEFAULT_TAGS_FILE}${NC}) doesn't exist so have created it"
    touch "${DEFAULT_TAGS_FILE}"
    echo -e "$DEFAULT_TAGS" > $DEFAULT_TAGS_FILE
    echo
else
    #File exists, make sure all required tags are defined
    for entry in $(echo -e "${DEFAULT_TAGS}") ; do
        #echo "entry is [$entry]"
        #if $(echo "${entry}" | grep -q "${TAG_VARIABLE_REGEX}") ; then 
        if [[ "${entry}" =~ "_TAG=" ]]; then
            #extract the tag name from the default tags entry e.g. "    STROOM_TAG=master-SNAPSHOT   " => "STROOM_TAG"
            tagName="$(echo "${entry}" | grep -oP "[A-Z0-9_]*_TAG(?=\=)")"
            #echo "tagName is $tagName"
            #check if tagName doesn't exist in the file and if not add it
            #commented lines are supported using negative lookbehind
            if ! grep -qP "(?<!#)${tagName}" "${DEFAULT_TAGS_FILE}"; then
                #un-commented tagName doesn't exist in DEFAULT_TAGS_FILE so add it
                echo -e "Adding ${GREEN}${entry}${NC} to file ${BLUE}${DEFAULT_TAGS_FILE}${NC}"
                echo "${entry}" >> "${DEFAULT_TAGS_FILE}"
            fi
        fi
    done
fi

#Check script arguments
if [ "$#" -eq 0 ] || ! [ -f "$1" ]; then
  echo -e "${RED}ERROR - Invalid arguments${NC}" >&2
  echo -e "${GREEN}Usage: $0 dockerComposeYmlFile optionalExtraArgsForDocker${NC}" >&2
  echo "E.g: $0 compose/everything.yml" >&2
  echo "E.g: $0 compose/everything.yml --build" >&2
  echo
  echo -e "Custom docker tags can be defined in ${BLUE}${DEFAULT_TAGS_FILE}${NC}"
  echo 
  echo -e "${BLUE}Possible compose files:${NC}" >&2
  ls -1 ./compose/*.yml
  exit 1
fi

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


#Read in the docker tag variables, either defaulted or as provided by the user
source "${DEFAULT_TAGS_FILE}"

ymlFile=$1

setDockerTagValue() {
    repoName=$1
    tagName=$2
    tagValue=$3
    padding='                       '
    url="${DOCKER_TAGS_URL_PREFIX}${repoName}${DOCKER_TAGS_URL_SUFFIX}"
    echo -e "Using ${tagName}${padding:${#tagName}}= ${GREEN}${tagValue}${NC}\t$url"
    #export the variable so docker-compose can see it and use it
    export "$tagName"
}

#check if the yml file contains any Docker tag variables, i.e. ${xxxx_TAG}
if grep -q "${TAG_VARIABLE_REGEX}" $ymlFile; then
    echo
    echo "The following Docker tags will be used for this compose file:"
    #scan the yml file for any docker tag variables and then display their current
    #value (or a default) to the user for confirmation
    for tag in $(grep -o "${TAG_VARIABLE_REGEX}" $ymlFile | sed -E 's/\$\{(.*)}/\1/g'); do 

        #IMAGE SPECIFIC CODE
        if [ "$tag" = "STROOM_TAG" ]; then
            setDockerTagValue "stroom" "STROOM_TAG" "${STROOM_TAG}"
        elif [ "$tag" = "STROOM_STATS_TAG" ]; then
            setDockerTagValue "stroom-stats" "STROOM_STATS_TAG" "${STROOM_STATS_TAG}"
        fi
    done

    echo
    echo -e "Docker tags can be changed in the file ${BLUE}${DEFAULT_TAGS_FILE}${NC} in the form:"
    echo -e "  ${YELLOW}xxxxxxx_TAG=master-SNAPSHOT${NC}"
    echo
    read -rsp $'Press space to continue, or ctrl-c to exit...\n' -n1 keyPressed

    if [ "$keyPressed" = '' ]; then
        echo
    else
        echo "Exiting"
        exit 0
    fi
fi

#args from 2 onwards are extra docker args
extraDockerArgs="${*:2}"

projectName=$(basename $ymlFile | sed 's/\.yml$//')

#Ensure we have the latest image of stroom from dockerhub, unless our TAG contains LOCAL
#Needed for floating tags like *-SNAPSHOT or v6

pullLatestImageIfNeeded() {
    repoName=$1
    tagName=$2
    tagValue=$3
    #see if the repo name is in the compose file
    if grep -q "${repoName}:" $ymlFile ; then
        if grep -qP "${tagName}=.*LOCAL.*" "$DEFAULT_TAGS_FILE" ; then
            echo
            echo -e "Compose file contains ${GREEN}${repoName}${NC} but is using a locally built image, dockerhub will not be checked for a new version"
        else
            echo
            echo -e "Compose file contains ${GREEN}${repoName}${NC}, checking for any updates to the ${GREEN}${repoName}:${tagValue}${NC} image on dockerhub"
            docker-compose -f "$ymlFile" -p "$projectName" pull ${repoName}
        fi
    fi
}

#IMAGE SPECIFIC CODE
pullLatestImageIfNeeded "stroom" "STROOM_TAG" ${STROOM_TAG}
pullLatestImageIfNeeded "stroom-stats" "STROOM_STATS_TAG" ${STROOM_STATS_TAG}

echo 
echo "Bouncing project $projectName with using $ymlFile with additional arguments for 'docker-compose up' [${extraDockerArgs}]"
echo "This will restart any existing containers (preserving their state), or create any containers that do not exist."
echo "If you want to rebuild images from your own dockerfiles pass the '--build' argument"
echo 

#pass any additional arguments after the yml filename direct to docker-compose
docker-compose -f $ymlFile -p $projectName stop && docker-compose -f $ymlFile -p $projectName up $extraDockerArgs
