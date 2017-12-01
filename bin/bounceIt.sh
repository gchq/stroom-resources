#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Script to start up a docker compose yml configuration. The script will
# look for any variables of the form '${xxxxx_TAG}' in the compose file 
# and set the value of those variables according to the values found in 
# TAGS_FILE
#
# This allows you to run the various stroom-* containers with any combination
# of image versions that you chose.
#
# If you want to add a new docker imaage that supports custom tags then
# you need to add code in here in three places, search below for 
# 'IMAGE SPECIFIC CODE'
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#exit the script on any error
set -e

#List of hostnames that need to be added to /etc/hosts to resolve to 127.0.0.1
LOCAL_HOST_NAMES="kafka hbase"

#Location of all local stroom configuration
STROOM_CONF_DIR="${HOME}/.stroom"

#Location of the file used to define the docker tag variable values
TAGS_FILE="${STROOM_CONF_DIR}/docker.tags"

#These are the default values for each docker tag variable
#This string is used to create the TAGS_FILE if it doesn't exist
#and as the definitive list of all tags to check for
#Tag name must match [A-Z0-9_]+
#IMAGE SPECIFIC CODE
DEFAULT_TAGS="\
#comment lines are supported like this (no space before or after '#')
STROOM_TAG=master-SNAPSHOT
STROOM_AUTH_SERVICE_TAG=master-SNAPSHOT
STROOM_AUTH_UI_TAG=master-SNAPSHOT
STROOM_ANNOTATIONS_SERVICE_TAG=master-SNAPSHOT
STROOM_ANNOTATIONS_UI_TAG=master-SNAPSHOT
STROOM_QUERY_ELASTIC_TAG=master-SNAPSHOT
STROOM_STATS_TAG=master-SNAPSHOT"

#regex used to locate a docker tag variable in a docker-compose .yml file
TAG_VARIABLE_REGEX="\${.*_TAG}" 

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

#Constants for the dockerhub URL
DOCKER_TAGS_URL_PREFIX="from ${BLUE}https://hub.docker.com/r/gchq/"
DOCKER_TAGS_URL_SUFFIX="/tags/${NC}"

echo

#Ensure we have a docker.tags file, if not create one using the content of the DEFAULT_TAGS string
if [ ! -f ${TAGS_FILE} ]; then
    echo -e "Default docker tags file (${BLUE}${TAGS_FILE}${NC}) doesn't exist so have created it"
    mkdir -p "${STROOM_CONF_DIR}"
    touch "${TAGS_FILE}"
    echo -e "$DEFAULT_TAGS" > $TAGS_FILE
    echo
else
    #File exists, make sure all required tags are defined
    #Loop round all entries in DEFAULT_TAGS, ignoreing the top comment line
    #assumes no spaces in 'tag_name=version'
    for entry in $(echo -e "${DEFAULT_TAGS}" | egrep -v "^#.*\n") ; do
        #echo "entry is [$entry]"
        if [[ "${entry}" =~ "_TAG=" ]]; then
            #extract the tag name from the default tags entry e.g. "    STROOM_TAG=master-SNAPSHOT   " => "STROOM_TAG"
            tagName="$(echo "${entry}" | grep -o "[A-Z0-9_]*_TAG")"
            #echo "tagName is $tagName"
            #check if tagName doesn't exist in the file (in un-commented form) and if it doesn't exist, add it
            if ! grep -q "^\s*${tagName}" "${TAGS_FILE}"; then
                #un-commented tagName doesn't exist in TAGS_FILE so add it
                echo -e "Adding ${GREEN}${entry}${NC} to file ${BLUE}${TAGS_FILE}${NC}"
                echo
                echo "${entry}" >> "${TAGS_FILE}"
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
  echo -e "Custom docker tags can be defined in ${BLUE}${TAGS_FILE}${NC}"
  echo 
  echo -e "${BLUE}Possible compose files:${NC}" >&2
  ls -1 ./compose/*.yml
  exit 1
fi

isHostMissing=""

#Some of the docker containers required entries in your local hosts file to
#work correctly. This code checks they are all there
for host in $LOCAL_HOST_NAMES; do
    if [ $(cat /etc/hosts | grep -e "127\.0\.0\.1\s*$host" | wc -l) -eq 0 ]; then 
        echo -e "${RED}ERROR${NC} - /etc/hosts is missing an entry for \"127.0.0.1 $host\""
        isHostMissing=true
        echo "Add the following line to /etc/hosts:"
        echo -e "${GREEN}127.0.0.1 $host${NC}"
        echo
    fi
done

if [ $isHostMissing ]; then
    echo "Quiting!"
    exit 1
fi


#Read in the docker tag variables, either defaulted or as provided by the user
source "${TAGS_FILE}"

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
    echo "The following Docker tags will be used for this compose file:"
    echo
    #scan the yml file for any docker tag variables and then display their current
    #value (or a default) to the user for confirmation
    for tag in $(grep -o "${TAG_VARIABLE_REGEX}" $ymlFile | sed -E 's/\$\{(.*)}/\1/g'); do 

        #IMAGE SPECIFIC CODE
        if [ "$tag" = "STROOM_TAG" ]; then
            setDockerTagValue "stroom" "STROOM_TAG" "${STROOM_TAG}"
        elif [ "$tag" = "STROOM_STATS_TAG" ]; then
            setDockerTagValue "stroom-stats" "STROOM_STATS_TAG" "${STROOM_STATS_TAG}"
        elif [ "$tag" = "STROOM_ANNOTATIONS_SERVICE_TAG" ]; then
            setDockerTagValue "stroom-annotations-service" "STROOM_ANNOTATIONS_SERVICE_TAG" "${STROOM_ANNOTATIONS_SERVICE_TAG}"
        elif [ "$tag" = "STROOM_QUERY_ELASTIC_TAG" ]; then
            setDockerTagValue "stroom-query-elastic" "STROOM_QUERY_ELASTIC_TAG" "${STROOM_QUERY_ELASTIC_TAG}"
        elif [ "$tag" = "STROOM_ANNOTATIONS_UI_TAG" ]; then
            setDockerTagValue "stroom-annotations-ui" "STROOM_ANNOTATIONS_UI_TAG" "${STROOM_ANNOTATIONS_UI_TAG}"
        elif [ "$tag" = "STROOM_AUTH_SERVICE_TAG" ]; then
            setDockerTagValue "stroom-auth-service" "STROOM_AUTH_SERVICE_TAG" "${STROOM_AUTH_SERVICE_TAG}"
        elif [ "$tag" = "STROOM_AUTH_UI_TAG" ]; then
            setDockerTagValue "stroom-auth-ui" "STROOM_AUTH_UI_TAG" "${STROOM_AUTH_UI_TAG}"
        fi
    done

    echo
    echo -e "Docker tags can be changed in the file ${BLUE}${TAGS_FILE}${NC} in the form:"
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

#method to pull updated image files from dockerhub if required
#This is to support -SNAPSHOT tags that are floating
pullLatestImageIfNeeded() {
    repoName=$1
    tagName=$2
    tagValue=$3
    #see if the repo name is in the compose file
    if grep -q "${repoName}:" $ymlFile ; then
        if grep -q "${tagName}=.*LOCAL.*" "$TAGS_FILE" ; then
            echo
            echo -e "Compose file contains ${GREEN}${repoName}${NC} but is using a locally built image, DockerHub will not be checked for a new version"
        else
            #use 'docker-compose ps' to establish if we already have a container for this service
            #if we do then we won't do a docker-compose pull as that would trash any local state
            #if a user wants refreshed images from dockerhub then they should delete their containers first
            #using the dockerTidyUp script or similar
            existingContainerId=$(docker-compose -f "$ymlFile" -p "$projectName" ps -q ${repoName})
            if [ "x" = "${existingContainerId}x" ]; then
                #no existing container so do a pull to check for updates
                #If the image has a fixed tag version e.g. master-20171008-DAILY, then no change will be
                #detected
                echo
                echo -e "Compose file contains ${GREEN}${repoName}${NC}, checking for any updates to the ${GREEN}${repoName}:${tagValue}${NC} image on dockerhub"
                docker-compose -f "$ymlFile" -p "$projectName" pull ${repoName}
            else
                echo
                echo -e "Compose file contains ${GREEN}${repoName}${NC} but you already have a container with ID ${existingContainerId}, won't check dockerhub for updates"
            fi
        fi
    fi
}

#IMAGE SPECIFIC CODE
pullLatestImageIfNeeded "stroom" "STROOM_TAG" ${STROOM_TAG}
pullLatestImageIfNeeded "stroom-stats" "STROOM_STATS_TAG" ${STROOM_STATS_TAG}
pullLatestImageIfNeeded "stroom-annotations-service" "STROOM_ANNOTATIONS_SERVICE_TAG" ${STROOM_ANNOTATIONS_SERVICE_TAG}
pullLatestImageIfNeeded "stroom-annotations-ui" "STROOM_ANNOTATIONS_UI_TAG" ${STROOM_ANNOTATIONS_UI_TAG}
pullLatestImageIfNeeded "stroom-auth-service" "STROOM_AUTH_SERVICE_TAG" ${STROOM_AUTH_SERVICE_TAG}
pullLatestImageIfNeeded "stroom-auth-ui" "STROOM_AUTH_UI_TAG" ${STROOM_AUTH_UI_TAG}

echo 
echo -e "Bouncing project $projectName with using $ymlFile with additional arguments for 'docker-compose up' [${GREEN}${extraDockerArgs}${NC}]"
echo "This will restart any existing containers (preserving their state), or create any containers that do not exist."
echo "If you want to rebuild images from your own dockerfiles pass the '--build' argument"
echo 

# We need to know where we're running this from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# We need the IP to transpose into our config

# Code required to find IP address is different in MacOS
if [ "$(uname)" == "Darwin" ]; then
  ip=`ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}'`
else
  ip=`ip route get 1 | awk '{print $NF;exit}'`
fi

# This is used by the docker-compose YML files, so they can tell a browser where to go
echo -e "Using the following IP as the advertised host: ${GREEN}$ip${NC}"
export STROOM_RESOURCES_ADVERTISED_HOST=$ip

# NGINX: creates config files from templates, adding in the correct IP address
deployRoot=$DIR/"../deploy"
echo -e "Creating nginx/nginx.conf using ${GREEN}$ip${NC}"
cat $deployRoot/template/nginx.conf | sed "s/<SWARM_IP>/$ip/g" | sed "s/<STROOM_URL>/$ip/g" | sed "s/<AUTH_UI_URL>/$ip/g" > $deployRoot/nginx/nginx.conf
echo

echo "Using the following docker images:"
echo
for image in $(docker-compose -f $ymlFile config | grep "image:" | sed 's/.*image: //'); do
    echo -e "  ${GREEN}${image}${NC}"
done
echo

#pass any additional arguments after the yml filename direct to docker-compose
#This will create containers as required and then start up the new or existing containers
docker-compose -f $ymlFile -p $projectName stop && docker-compose -f $ymlFile -p $projectName up $extraDockerArgs
