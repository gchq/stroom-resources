#!/usr/bin/env bash 

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
# Script to aid the running of the docker containers used in the stroom family.
# The script will validate 

#exit the script on any error
set -e

#Get the dir that this script lives in, no matter where it is called from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#List of hostnames that need to be added to /etc/hosts to resolve to 127.0.0.1
LOCAL_HOST_NAMES="kafka hbase"

#Location of the file used to define the docker tag variable values
TAGS_FILE="${SCRIPT_DIR}/docker.tags"

#The docker-compose yml file that defines all the docker services for the whole stroom family
ALL_SERVICES_COMPOSE_FILE="${SCRIPT_DIR}/compose/everything.yml"

DEFAULT_TAGS_HEADER="#comment lines are supported like this (no space before or after '#')"

#regex used to locate a docker tag variable in a docker-compose .yml file
TAG_VARIABLE_REGEX="\${.*_TAG.*}" 

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

#Constants for the dockerhub URL
DOCKER_TAGS_URL_PREFIX="from ${BLUE}https://hub.docker.com/r/gchq/"
DOCKER_TAGS_URL_SUFFIX="/tags/${NC}"

SUPPORTED_COMPOSE_CMDS_REGEX="(start|stop|restart|up|down)"
DEFAULT_COMPOSE_CMD="up"

showUsage() {
    echo "Usage: $0 [COMPOSE_COMMAND] [OPTION]... [EXTRA_COMPOSE_ARG]... [SERVICE_NAME]..."
    echo "COMPOSE_COMMAND - One of ${SUPPORTED_COMPOSE_CMDS_REGEX}, if not supplied a \"stop\" and then \"${DEFAULT_COMPOSE_CMD}\" will be performed"
    echo "OPTIONs:"
    echo "  -h - Show this help text"
    echo "  -e - Rely on existing environment variables for any docker tags, the docker.tags file will not be used"
    echo "  -x - Do not check hosts file for docker related entries"
    echo "  -y - Do not prompt for confirmation, e.g. when run from a script"
    echo "EXTRA_COMPOSE_ARGs - Any additional arguments for docker-compose, of the form \"--argName\", e.g. \"--build\""
    echo "e.g.: $0 serviceX serviceY"
    echo "e.g.: $0 up -e -y --build --verbose serviceX serviceY"
}


printValidServiceNames() {
    echo "Valid service names are:"
    echo
    for serviceName in $(docker-compose -f ${ymlFile} config --services | sort); do
        echo -e "  ${GREEN}${serviceName}${NC}"
    done
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~start~of~script~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


echo
isHostMissing=false
extraComposeArguments=""
requireConfirmation=true
requireHostFileCheck=true
useEnvironmentVariables=false
runStopCmdFirst=false
ymlFile=${ALL_SERVICES_COMPOSE_FILE}
projectName=$(basename $ymlFile | sed 's/\.yml$//')

if [[ "$1" =~ $SUPPORTED_COMPOSE_CMDS_REGEX ]]; then
    composeCmd=$1
    #shift the args by one, discarding the one we have just read
    shift
else
    #No compose command was supplied so do a 'stop' then 'up' on the specified services
    runStopCmdFirst=true
    composeCmd="$DEFAULT_COMPOSE_CMD"
fi

extraComposeArguments=""

optspec=":a:ehy-:"
#The following code to parse long args, e.g. --build, is derived from an answer in
#https://stackoverflow.com/questions/402377/using-getopts-in-bash-shell-script-to-get-long-and-short-command-line-options
while getopts "$optspec" optchar; do
    #echo "Parsing $optchar"
    case "${optchar}" in
        -)
            #An additional double-dash docker-compose argument
            #echo "Using additionl compose argument --${OPTARG}"
            extraComposeArguments="${extraComposeArguments} --${OPTARG}"
            ;;
        e)
            #echo "Using environment variables"
            useEnvironmentVariables=true
            ;;
        h)
            #help
            showUsage
            exit 1
            ;;
        x)
            #echo "Will not check hosts file"
            requireHostFileCheck=false
            ;;
        y)
            #echo "Will not prompt for confirmation"
            requireConfirmation=false
            ;;
        *)
            echo -e "${RED}Unknown argument: '-${OPTARG}'${NC}" >&2
            echo
            showUsage
            exit 1
            ;;
    esac
done

#discard the args parsed so far
shift $((OPTIND -1))
serviceNames="$@"

if [ $# = 0 ]; then
    echo -e "${RED}No SERVICE_NAMEs specified${NC}" >&2
    showUsage
    echo 
    printValidServiceNames
    exit 1
else
    validServiceNameRegex=""
    for serviceName in $(docker-compose -f ${ymlFile} config --services | sort); do
        validServiceNameRegex="${validServiceNameRegex}|${serviceName}"
    done

    #strip leading pipe char
    validServiceNameRegex=$(echo "$validServiceNameRegex" | sed -r 's/\|//')
    validServiceNameRegex="(${validServiceNameRegex})"

    for serviceName in $serviceNames; do
        #echo "  Service: [${serviceName}]"
        if [[ "${serviceName}" =~ ^-.* ]]; then
            echo -e "${RED}OPTIONS must be specified before SERVICE_NAMEs${NC}" >&2
            echo
            showUsage
            exit 1
        elif [[ ! "${serviceName}" =~ $validServiceNameRegex ]]; then
            echo -e "${RED}SERVICE_NAME [${GREEN}${serviceName}${RED}] is not valid${NC}" >&2
            echo
            showUsage
            echo 
            printValidServiceNames
            exit 1
        fi
    done
fi

#strip any leading whitespace
extraComposeArguments=$(echo "$extraComposeArguments" | sed -r 's/\s//')

if $requireHostFileCheck; then
    #Some of the docker containers required entries in your local hosts file to
    #work correctly. This code checks they are all there
    for host in $LOCAL_HOST_NAMES; do
        if [ $(cat /etc/hosts | grep -e "127\.0\.0\.1\s*$host" | wc -l) -eq 0 ]; then 
            echo -e "${RED}ERROR${NC} - /etc/hosts is missing an entry for ${GREEN}\"127.0.0.1 $host\"${NC}"
            isHostMissing=true
            echo "Add the following line to /etc/hosts:"
            echo -e "${GREEN}127.0.0.1 $host${NC}"
            echo
        fi
    done

    if $isHostMissing; then
        exit 1
    fi
fi

if ! $useEnvironmentVariables; then
    #read all the container yml files to find any _TAG variables and convert them from something like:
    #${STROOM_ANNOTATIONS_SERVICE_TAG:-v0.1.5-alpha.4}
    #into something like:
    #STROOM_ANNOTATIONS_SERVICE_TAG=v0.1.5-alpha.4
    #If the variable has no dfeault part (e.g. ${..._TAG}) then just use 'master-SNAPSHOT'
    defaultTags=$(cat ${SCRIPT_DIR}/compose/containers/*.yml | grep -o "\${.*_TAG.*}" | uniq | sed -E 's/\$\{(.*_TAG):?-?(.*)}/\1=\2/' | sed -E 's/(_TAG=)$/\1master-SNAPSHOT/')
    #Ensure we have a docker.tags file, if not create one using the content of the defaultTags string
    if [ ! -f ${TAGS_FILE} ]; then
        echo -e "Default docker tags file (${BLUE}${TAGS_FILE}${NC}) doesn't exist so have created it with the following content"
        touch "${TAGS_FILE}"
        echo "$DEFAULT_TAGS_HEADER" > $TAGS_FILE
        echo -e "$defaultTags" >> $TAGS_FILE
        echo
        cat $TAGS_FILE
        echo
    else
        #File exists, make sure all required tags are defined
        #Loop round all entries in defaultTags, ignoring the top comment line
        #assumes no spaces in 'tag_name=version'
        for entry in $(echo -e "${defaultTags}" | egrep -v "^#.*\n") ; do
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

    #export all entires in the tags file as environment variables so they are available to docker-compose to do variable substitution
    for entry in $(cat "${TAGS_FILE}" | egrep -v "^#.*") ; do
        #echo "Exporting ${entry}"
        export "${entry}"
    done
fi

#'docker-compose config' will perform any tag substitution so the tags here will have come from the TAGS_FILE or env vars or defaults
allImages=$(docker-compose -f $ymlFile config | egrep "image: ")

echo "The following Docker services and tags will be used:"
echo

#print out all the services/images we are trying to use (i.e. potentially a subset of all those in the yml file
for serviceName in ${serviceNames}; do

    if ! egrep -q "^\s*${serviceName}:\s*$" $ymlFile; then
        echo
        echo -e "${RED}ERROR${NC} - ${BLUE}${ymlFile}${NC} does not contain service ${GREEN}${serviceName}${NC}"
        exit 1
    else
        image=$(echo "$allImages" | grep "${serviceName}:" | sed 's/.*image: //')
        #image=$(docker-compose -f ${ymlFile} config | grep -Pzo "${serviceName}:\s*\n(.|\n)*?\s*image:\s*.*\n" | grep -zo "image.*" | sed 's/image: //')
        #if [ "${image}x" != "x" ]; then
            #echo
            #echo -e "${RED}ERROR - Unable to establish image name for service ${GREEN}${serviceName}${NC}"
            #exit 1
        #fi

        #TODO figure out a way to get the image for the serviceName as we currently assume that the
        #repo name in the image matches the serviceName
        padding='                                '
        echo -e "  ${GREEN}${serviceName}${padding:${#serviceName}} - ${image}${NC}"
    fi
done

for serviceName in ${serviceNames}; do
    image=$(echo "$allImages" | grep "${serviceName}:" | sed 's/.*image: //')

    #Ensure we have the latest image of stroom from dockerhub, unless our TAG contains LOCAL
    #Needed for floating tags like *-SNAPSHOT or v6

    #method to pull updated image files from dockerhub if required
    #This is to support -SNAPSHOT tags that are floating
    if [ "${image}x" != "x" ]; then
        if grep -q "${tagName}=.*LOCAL.*" "$TAGS_FILE" ; then
            echo
            echo -e "${GREEN}${image}${NC} is a locally built image, DockerHub will not be checked for a new version"
        else
            #use 'docker-compose ps' to establish if we already have a container for this service
            #if we do then we won't do a docker-compose pull as that would trash any local state
            #if a user wants refreshed images from dockerhub then they should delete their containers first
            #using the dockerTidyUp script or similar
            existingContainerId=$(docker-compose -f "$ymlFile" -p "$projectName" ps -q ${serviceName})
            if [ "x" = "${existingContainerId}x" ]; then
                #no existing container so do a pull to check for updates
                #If the image has a fixed tag version e.g. master-20171008-DAILY, then no change will be
                #detected
                echo
                echo -e "Checking for any updates to the ${GREEN}${serviceName}${NC} image on dockerhub"
                #docker-compose -f "$ymlFile" -p "$projectName" pull ${repoName}
            else
                echo
                echo -e "${GREEN}${serviceName}${NC} already has a container with ID ${BLUE}${existingContainerId}${NC}, won't check dockerhub for updates"
            fi
        fi
    fi
done

if $useEnvironmentVariables ; then
    echo
    echo "Using environment variables to resolve any docker tag variables"
else
    echo
    echo -e "Docker tags can be changed in the file ${BLUE}${TAGS_FILE}${NC} in the form:"
    echo -e "  ${YELLOW}xxxxxxx_TAG=master-SNAPSHOT${NC}"
fi

# We need the IP to transpose into our config

# Code required to find IP address is different in MacOS
if [ "$(uname)" == "Darwin" ]; then
  ip=`ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}'`
else
  ip=`ip route get 1 | awk '{print $NF;exit}'`
fi

# This is used by the docker-compose YML files, so they can tell a browser where to go
echo
echo -e "Using the following IP as the advertised host: ${GREEN}$ip${NC}"
export STROOM_RESOURCES_ADVERTISED_HOST=$ip

# NGINX: creates config files from templates, adding in the correct IP address
deployRoot="${SCRIPT_DIR}/../deploy"
echo -e "Creating nginx/nginx.conf using ${GREEN}$ip${NC}"
cat $deployRoot/template/nginx.conf | sed "s/<ADVERTISED_HOST>/$ip/g" > $deployRoot/nginx/nginx.conf
echo

#echo "Using the following docker images:"
#echo
#for image in $(docker-compose -f $ymlFile config | grep "image:" | sed 's/.*image: //'); do
    #echo -e "  ${GREEN}${image}${NC}"
#done
#echo

echo -e "Using command [${GREEN}${composeCmd}${NC}] with additional arguments [${GREEN}${extraComposeArguments}${NC}] against the following services [${GREEN}${serviceNames}${NC}]"
if [ "$composeCmd" = "up" ]; then
    echo "If you want to rebuild images from your own dockerfiles pass the '--build' argument"
fi

if $requireConfirmation; then
    echo
    read -rsp $'Press space to continue, or ctrl-c to exit...\n' -n1 keyPressed

    if [ "$keyPressed" = '' ]; then
        echo
    else
        echo "Exiting"
        exit 0
    fi
fi

echo 
if $runStopCmdFirst; then
    echo "Ensuring ALL servcies are stopped"
    docker-compose -f $ymlFile -p $projectName stop 
fi

#pass any additional arguments after the yml filename direct to docker-compose
#This will create containers as required and then start up the new or existing containers
docker-compose -f $ymlFile -p $projectName $extraComposeArguments $composeCmd $serviceNames

exit 0
