#!/usr/bin/env bash 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# 
# Script to aid the running of the docker containers used in the stroom family.
# See ./bouncIt.sh -h for details

# WARNING - This script relies heavily on tools like sed, grep, awk, etc. and was
# primarily written/tested on GNU Linux.  If you do not have the gnu versions of 
# these binaries the script may not work.  If you are using macOS you will probably
# need to install the GNU versions with homebrew.

#exit the script on any error
set -e

#Get the dir that this script lives in, no matter where it is called from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#List of hostnames that need to be added to /etc/hosts to resolve to 127.0.0.1
LOCAL_HOST_NAMES=" \
kafka \
hbase \
stroom \
stroom-auth-service \
stroom-auth-ui \
stroom-annotations-service \
stroom-annotations-ui \
stroom-query-elastic-service \
stroom-query-elastic-ui"

#Location of the file used to define the docker tag variable values
TAGS_FILE="${SCRIPT_DIR}/local.env"

#Temporary file used to hold environment variable for export
TEMPORARY_ENV_FILE="${SCRIPT_DIR}/.temp.env"

#The docker-compose yml file that defines all the docker services for the whole stroom family
ALL_SERVICES_COMPOSE_FILE="${SCRIPT_DIR}/compose/everything.yml"

#Header text for use when creating a new local.env file
#to generate the list of _HOST variables run the following 
#cat compose/containers/*.yml | grep -oE "\\$\{[A-Z_]*_HOST(:-.*)?}" | sort | uniq | sed -E 's/\$\{([A-Z_]*)(:-.*)?}/\1=\\${STROOM_RESOURCES_ADVERTISED_HOST}/'
DEFAULT_TAGS_HEADER='#comment lines are supported like this (no space before or after "#")

#If bounceIt.sh is unable to determine the IP address of this machine from 
#the operating system you can hard code it here. This must be the public facing
#IP address, e.g. 192.168.0.1, NOT an address local to the machine like 127.0.0.1 .
#STROOM_RESOURCES_ADVERTISED_HOST=x.x.x.x

#SERVICE_LIST can be set to a list of space delimited services to remove the need 
#to define multiple services on the command line. Therefore uncomment some of the
#following lines to build the required SERVICE_LIST
SERVICE_LIST=""
#SERVICE_LIST="${SERVICE_LIST} elasticsearch"
#SERVICE_LIST="${SERVICE_LIST} fake-smtp"
#SERVICE_LIST="${SERVICE_LIST} hbase"
#SERVICE_LIST="${SERVICE_LIST} kafka"
#SERVICE_LIST="${SERVICE_LIST} kibana"
#SERVICE_LIST="${SERVICE_LIST} nginx"
#SERVICE_LIST="${SERVICE_LIST} stroom"
#SERVICE_LIST="${SERVICE_LIST} stroom-annotations-db"
#SERVICE_LIST="${SERVICE_LIST} stroom-annotations-service"
#SERVICE_LIST="${SERVICE_LIST} stroom-annotations-ui"
#SERVICE_LIST="${SERVICE_LIST} stroom-auth-service"
#SERVICE_LIST="${SERVICE_LIST} stroom-auth-service-db"
#SERVICE_LIST="${SERVICE_LIST} stroom-auth-ui"
#SERVICE_LIST="${SERVICE_LIST} stroom-db"
#SERVICE_LIST="${SERVICE_LIST} stroom-query-elastic-svc"
#SERVICE_LIST="${SERVICE_LIST} stroom-query-elastic-ui"
#SERVICE_LIST="${SERVICE_LIST} stroom-stats"
#SERVICE_LIST="${SERVICE_LIST} stroom-stats-db"
#SERVICE_LIST="${SERVICE_LIST} zookeeper"

#If you are a developer running one of the services in an IDE then you will need to
#uncommennt the _HOST variable for that service here so that it uses the host''s address
#when advertisig its address, this then makes it visible to services running in docker.
#E.g. if you run stroom in an IDE with all other services in docker, uncomment 
#the STROOM_HOST line.
#ELASTIC_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#HBASE_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#KAFKA_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#NGINX_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_ANNOTATIONS_DB_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_ANNOTATIONS_UI_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_AUTH_DB_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_AUTHORISATION_SERVICE_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_AUTH_SERVICE_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_AUTH_UI_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_AUTH_UI_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_DB_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_ELASTIC_SERVICE_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_ELASTIC_UI_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}
#STROOM_STATS_DB_HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}


#The following variables set the docker tag used for specific services'
#--------------end of DEFAULT_TAGS_HEADER---------------------------

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

SUPPORTED_COMPOSE_CMDS_REGEX="^(start|stop|restart|up|down|top|ps|rm|logs|kill|create)"
CMDS_FOR_IMAGE_CHECK="^(up|create)"
DEFAULT_COMPOSE_CMD="up"
COMPOSE_CMMD_DELIMITER=":"

printValidServiceNames() {
    echo "Valid service names are:"
    echo
    for serviceName in $allServices; do
        echo -e "  ${GREEN}${serviceName}${NC}"
    done
}

showUsage() {
    echo -e "Usage: ${BLUE}$0 [COMPOSE_COMMAND] [OPTION]... [EXTRA_COMPOSE_ARG]... [SERVICE_NAME]...${NC}"
    echo -e "COMPOSE_COMMAND - One of ${SUPPORTED_COMPOSE_CMDS_REGEX}, if not supplied a \"stop\" and then \"${DEFAULT_COMPOSE_CMD}\" will be performed"
    echo -e "                  If you want to pass extra arguments to the docker-compose command then add them onto the end of the command"
    echo -e "                  separated by a '${COMPOSE_CMMD_DELIMITER}' (e.g. up:-d:--build) or "
    echo -e "                  surround it all in quotes (e.g. 'up -d --build')"
    echo -e "OPTIONs:"
    echo -e "  ${GREEN}-e${NC} - Rely on existing environment variables for any docker tags, the ${BLUE}local.env${NC} file will be ignored"
    echo -e "  ${GREEN}-f${NC} - Use a custom configuration file to supply service names, tags and environment values, e.g. \"${BLUE}-f ./stroom5.env${NC}\""
    echo -e "  ${GREEN}-h${NC} - Show this help text"
    echo -e "  ${GREEN}-i${NC} - Do not check dockerhub for more recent versions of tagged images"
    echo -e "  ${GREEN}-x${NC} - Do not check hosts file for docker related entries"
    echo -e "  ${GREEN}-y${NC} - Do not prompt for confirmation, e.g. when run from a script"
    echo -e "  NOTE: if nether -f or -e are specified the file ${BLUE}${TAGS_FILE}${NC} will be used (and created if it doesn't exist)"
    echo -e "e.g.: ${BLUE}$0 serviceX serviceY${NC}    - Executes stop then '${DEFAULT_COMPOSE_CMD}' for serviceX and serviceY"
    echo -e "e.g.: ${BLUE}$0 'up -d --build' -e -y serviceX serviceY${NC}    - Executes 'up -d --build' for serviceX and serviceY with no confirmation and using environment variables"
    echo -e "e.g.: ${BLUE}$0 up -f stroom5.env${NC}    - Executes 'up' using the configuration in stroom5.env"
    echo
    printValidServiceNames
}

createOrUpdateLocalTagsFile() {
    #read all the container yml files to find any _TAG variables and convert them from something like:
    #${STROOM_ANNOTATIONS_SERVICE_TAG:-v0.1.5-alpha.4}
    #into something like:
    #STROOM_ANNOTATIONS_SERVICE_TAG=v0.1.5-alpha.4
    #If the variable has no default part (e.g. ${..._TAG}) then just use 'master-SNAPSHOT'
    local defaultTags=$(cat ${SCRIPT_DIR}/compose/containers/*.yml | \
        grep -oE '\${[A-Z_]*_TAG.*}' | \
        sort | \
        uniq | \
        sed -E 's/\$\{(.*_TAG):?-?(.*)}/\1=\2/' | \
        sed -E 's/(_TAG=)$/\1master-SNAPSHOT/')
    #Ensure we have a TAGS_FILE file, if not create one using the content of the defaultTags string
    if [ ! -f ${TAGS_FILE} ]; then
        echo -e "Local configuration file (${BLUE}${TAGS_FILE}${NC}) doesn't exist so have created it with the following content"
        touch "${TAGS_FILE}"
        echo -e "$DEFAULT_TAGS_HEADER" > $TAGS_FILE
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
            if [[ "${entry}" =~ _TAG= ]]; then
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
}

exportFileContents() {
    local file=$1
    if [ ! -f $file ]; then
        echo -e "${RED}File ${file} doesn't exist${NC}" >&2
        exit 1
    fi

    echo
    echo -e "Using file ${BLUE}${file}${NC} to resolve any docker tags and other variables"

    #Export all un-commented entries in the file as environment variables so they are available to docker-compose to do variable substitution
    cat ${file} | egrep "^\s*[^#=]+=.*" | sed -E 's/([^=]+=)/export \1/' > ${TEMPORARY_ENV_FILE}

    #Source the export variables.
    source ${TEMPORARY_ENV_FILE}

    echo 
}

determineHostAddress() {
    # We need the IP to transpose into our config
    if [ "x${STROOM_RESOURCES_ADVERTISED_HOST}" != "x" ]; then
        ip="${STROOM_RESOURCES_ADVERTISED_HOST}"
        echo
        echo -e "Using IP ${GREEN}${ip}${NC} as the advertised host, as obtained from ${BLUE}STROOM_RESOURCES_ADVERTISED_HOST${NC}"
    else
        if [ "$(uname)" == "Darwin" ]; then
            # Code required to find IP address is different in MacOS
            ip=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}')
        else
            ip=$(ip route get 1 |awk 'match($0,"src [0-9\\.]+") {print substr($0,RSTART+4,RLENGTH-4)}')
        fi
        echo
        echo -e "Using IP ${GREEN}${ip}${NC} as the advertised host, as determined from the operating system"
    fi

    if [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo
        echo -e "${RED}ERROR${NC} IP address [${GREEN}${ip}${NC}] is not valid, try setting '${BLUE}STROOM_RESOURCES_ADVERTISED_HOST=x.x.x.x${NC}' in ${BLUE}local.env${NC}" >&2
        exit 1
    fi

    # This is used by the docker-compose YML files, so they can tell a browser where to go
    export STROOM_RESOURCES_ADVERTISED_HOST="${ip}"
    echo
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~start~of~script~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


echo
isHostMissing=false
hasEchoedMissingHostsMsg=false
extraComposeArguments=""
requireConfirmation=true
requireHostFileCheck=true
requireLatestImageCheck=true
useEnvironmentVariables=false
runStopCmdFirst=false
ymlFile=${ALL_SERVICES_COMPOSE_FILE}
projectName=$(basename $ymlFile | sed 's/\.yml$//')
allServices=$(docker-compose -f ${ymlFile} config --services | sort)
customEnvFile=""

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

optspec=":ef:hiyx"
while getopts "$optspec" optchar; do
    #echo "Parsing $optchar"
    case "${optchar}" in
        e)
            useEnvironmentVariables=true
            ;;
        f)
            if [ "${OPTARG}x" = "x" ]; then
                echo -e "${RED}-f argument requires a file path to be specified${NC}" >&2
                echo
                showUsage
                exit 1
            fi
            customEnvFile="${OPTARG}"
            ;;
        h)
            #help
            showUsage
            exit 1
            ;;
        i)
            requireLatestImageCheck=false
            ;;
        x)
            requireHostFileCheck=false
            ;;
        y)
            requireConfirmation=false
            ;;
        *)
            echo -e "${RED}ERROR${NC} Unknown argument: '-${OPTARG}'" >&2
            echo
            showUsage
            exit 1
            ;;
    esac
done

#discard the args parsed so far
shift $((OPTIND -1))
serviceNamesFromArgs="$@"

if $useEnvironmentVariables && [ -n "$customEnvFile" ]; then
    echo -e "${RED}Cannot use -f and -e arguments together${NC}" >&2
    showUsage
    exit 1
fi

if [ ! -f $customEnvFile ]; then
    echo -e "${RED}File ${customEnvFile} does not exist${NC}" >&2
    exit 1
fi

determineHostAddress

if [ -n "$customEnvFile" ]; then
    #custom env file
    exportFileContents "${customEnvFile}"
    if [ -z "${SERVICE_LIST}" ]; then
        echo -e "${RED}Warning${NC}: SERVICE_LIST has not been defined in file ${customEnvFile}"
    fi
elif ! $useEnvironmentVariables; then
    #default local env file
    createOrUpdateLocalTagsFile
    exportFileContents "${TAGS_FILE}"
else
    echo
    echo "Using environment variables to resolve any docker tags and other variables"
fi

#Try setting the service names list from the SERVICE_LIST env var, which may/may not be set.
serviceNames="${SERVICE_LIST}"
if [ -n "${serviceNamesFromArgs}" ] ; then
    if [ -n "${SERVICE_LIST}" ]; then
        echo -e "Overriding service names from ${BLUE}SERVICE_LIST${NC} [${GREEN}${SERVICE_LIST}${NC}] with those from the command line [${GREEN}${serviceNamesFromArgs}${NC}]"
    fi
    serviceNames="${serviceNamesFromArgs}"
fi
#strip any leading or trailing spaces
serviceNames=$(echo "$serviceNames" | sed -E 's/^\s//' | sed -E 's/\s$//')

if [ "${serviceNames}x" = "x" ]; then
    echo
    echo -e "No service names specified, the COMPOSE_COMMAND [${GREEN}${composeCmd}${NC}] will be applied to all services" >&2

    #build a space delim list of services so we can later display all the images in use
    for service in $allServices; do
        serviceNames+=" $service"
    done
    serviceNames=$(echo "$serviceNames" | sed -E 's/^\s//')
else
    validServiceNameRegex=""
    for serviceName in $(docker-compose -f ${ymlFile} config --services | sort); do
        validServiceNameRegex="${validServiceNameRegex}|${serviceName}"
    done

    #strip leading pipe char
    validServiceNameRegex=$(echo "$validServiceNameRegex" | sed -E 's/^\|//')
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
            exit 1
        fi
    done
fi

#REQUIRE_HOSTS_FILE_CHECK is used in the precanned env files as an override to
if $requireHostFileCheck && [[ "$REQUIRE_HOSTS_FILE_CHECK" != "false" ]]; then
    #Some of the docker containers required entries in your local hosts file to
    #work correctly. This code checks they are all there
    #echo -e "${RED}Performing hosts check${NC}"
    for host in $LOCAL_HOST_NAMES; do
        #echo "Checking for $host"
        if [ $(cat /etc/hosts | grep -e "^\s*127\.0\.0\.1\s*$host\s*$" | wc -l) -eq 0 ]; then 
            isHostMissing=true
            if ! $hasEchoedMissingHostsMsg; then
                echo
                echo -e "${RED}WARNING${NC} - /etc/hosts is missing required entries for stroom hosts"
                echo -e "These entries are only required if you have not set variables like"
                echo -e "'${BLUE}...._HOST=\${STROOM_RESOURCES_ADVERTISED_HOST}${NC}' in your env files"
                echo -e "Add the following lines to ${BLUE}/etc/hosts${NC} (or use the '${GREEN}-x${NC}' argument to ignore this check):"
                echo
                hasEchoedMissingHostsMsg=true
            fi
            echo -e "${GREEN}127.0.0.1 $host${NC}"
        fi
    done

    if $isHostMissing; then
        exit 1
    fi
fi


#'docker-compose config' will perform any tag substitution so the tags here will have come from the TAGS_FILE or env vars or defaults
allImages=$(docker-compose -f $ymlFile config | egrep "image: ")

echo
echo "The following Docker services and tags will be used:"
echo

#print out all the services/images we are trying to use (i.e. potentially a subset of all those in the yml file
for serviceName in ${serviceNames}; do

    if ! egrep -q "^\s*${serviceName}:\s*$" $ymlFile; then
        echo
        echo -e "${RED}ERROR${NC} - Service ${GREEN}${serviceName}${NC} does not exist in ${BLUE}${ymlFile}${NC}"
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

#only check for updated images for certain compose commands
if $requireLatestImageCheck && [[ "${composeCmd}" =~ ${CMDS_FOR_IMAGE_CHECK} ]] ; then
    for serviceName in ${serviceNames}; do
        #TODO this doesn't work for the likes of stroom-db because the image name is not the same
        #as the service name
        image=$(echo "$allImages" | grep "${serviceName}:" | sed 's/.*image: //')
        #echo "image: ${image}"

        #Ensure we have the latest image of stroom from dockerhub, unless our TAG contains LOCAL
        #Needed for floating tags like *-SNAPSHOT or v6

        #method to pull updated image files from dockerhub if required
        #This is to support -SNAPSHOT tags that are floating
        if [ "${image}x" != "x" ]; then
            if [[ "${image}" =~ .*(SNAPSHOT|LATEST|latest).* ]]; then
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
                    docker-compose -f "$ymlFile" -p "$projectName" pull ${serviceName}
                else
                    echo
                    echo -e "${GREEN}${serviceName}${NC} already has a container with ID ${BLUE}${existingContainerId}${NC}, won't check dockerhub for updates"
                fi

            else
                echo
                echo -e "${GREEN}${image}${NC} is a fixed image, DockerHub will not be checked for a new version"
            fi
        fi
    done
fi



#echo "Using the following docker images:"
#echo
#for image in $(docker-compose -f $ymlFile config | grep "image:" | sed 's/.*image: //'); do
    #echo -e "  ${GREEN}${image}${NC}"
#done
#echo

#The compose cmd may consist of a command with additional args delimited by a :, e.g. up:-d:--build
#so we replace the : with a space
composeCmd="$(echo "${composeCmd}" | sed "s/${COMPOSE_CMMD_DELIMITER}/ /g")"

echo -e "Using command [${GREEN}${composeCmd}${NC}] against the following services [${GREEN}${serviceNames}${NC}]"
if [ "$composeCmd" = "up" ]; then
    echo "If you want to rebuild images from your own dockerfiles pass the '--build' argument"
fi

#TODO the follow code is an attempt to inspect all the _HOST env vars and to check
#if the value for them can be resolve. Would need to use eval or similar to see what 
#value they have and if it cannt be resolved prompt for something to be added to 
#/etc/hosts
#hostVars=$(cat ${SCRIPT_DIR}/compose/containers/*.yml | \
    #grep -o -E '\${[A-Z_]*HOST.*}' | \
    #sort | \
    #uniq )

#for hostVar in $(echo -e "${hostVars}"); do
    #varName=$(echo "${hostVar}" | sed -E 's/\$\{([A-Z_]*)((:-)(.*))}/\1/')
    #varDefaulVal=$(echo "${hostVar}" | sed -E 's/\$\{([A-Z_]*)((:-)(.*))}/\4/')
    #echo "varName [${varName}] default [${varDefaulVal}]"
#done

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
    echo "Ensuring ALL services are stopped"
    docker-compose -f $ymlFile -p $projectName stop 
fi

#pass any additional arguments after the yml filename direct to docker-compose
#This will create containers as required and then start up the new or existing containers
docker-compose -f $ymlFile -p $projectName $composeCmd $extraComposeArguments $serviceNames

exit 0
