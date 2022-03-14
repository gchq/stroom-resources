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

# Allow the use of ** (bash 4+)
shopt -s globstar

#Get the dir that this script lives in, no matter where it is called from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#List of hostnames that need to be added to /etc/hosts to resolve to 127.0.0.1
LOCAL_HOST_NAMES=" \
kafka \
hbase"

# Location of the file used to store private values (db credentials)
mkdir -p ~/.stroom
CREDENTIALS_FILE=~/.stroom/credentials.sh
DEFAULT_CREDENTIALS_FILE=${SCRIPT_DIR}/credentials.default.sh

#Location of the file used to define the docker tag variable values
TAGS_FILE="${SCRIPT_DIR}/local.env"

#Temporary file used to hold environment variable for export
#TEMPORARY_ENV_FILE="${SCRIPT_DIR}/.temp.env"

YAML_FILES_DIR="${SCRIPT_DIR}/compose/containers"
YAML_OVERRIDES_DIR="${YAML_FILES_DIR}/overrides"

#Header text for use when creating a new local.env file
#to generate the list of _HOST variables run the following 
#cat compose/containers/*.yml | grep -oE "\\$\{[A-Z_]*_HOST(:-.*)?}" | sort | uniq | sed -E 's/\$\{([A-Z_]*)(:-.*)?}/\1=\\${STROOM_RESOURCES_ADVERTISED_HOST}/'
DEFAULT_TAGS_HEADER=$(<local.default.env)

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
LGREY='\e[37m'
DGREY='\e[90m'
NC='\033[0m' # No Color

SUPPORTED_COMPOSE_CMDS_REGEX="^(start|stop|restart|up|down|top|ps|rm|logs|kill|create)"
CMDS_FOR_IMAGE_CHECK="^(up|create)"
DEFAULT_COMPOSE_CMD="up"
COMPOSE_CMD_DELIMITER=":"
COMPOSE_PROJECT_NAME="bounceit"

run_docker_compose_cmd() {
    # We now have multiple yaml files that make up the project so we need
    # to add them all as -f args
    # First the base service definitions
    compose_file_args=()
    for yaml_file in "${YAML_FILES_DIR}"/*.yml; do
        compose_file_args+=( "-f" "${yaml_file}" )
    done
    # Second any override yml files that bring in mounts to shared volumes
    for yaml_file in "${YAML_OVERRIDES_DIR}"/*.yml; do
        compose_file_args+=( "-f" "${yaml_file}" )
    done

    if [[ "${isDebugModeEnabled}" = true ]]; then
        echo -e "${DGREY}docker-compose" \
            "--project-name ${COMPOSE_PROJECT_NAME}" \
            "${compose_file_args[*]}" \
            "${*}${NC}"
    fi

    docker-compose \
        --project-name "${COMPOSE_PROJECT_NAME}" \
        "${compose_file_args[@]}" \
        ${@}
}

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
    echo -e "                  separated by a '${COMPOSE_CMD_DELIMITER}' (e.g. up:-d:--build) or "
    echo -e "                  surround it all in quotes (e.g. 'up -d --build')"
    echo -e "OPTIONs:"
    echo -e "  ${GREEN}-d${NC} - Enable DEBUG mode. This will output additional information to aid diagnosing problems"
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
    local defaultTags
    # shellcheck disable=SC2016
    defaultTags=$(cat "${SCRIPT_DIR}"/compose/containers/*.yml | \
        grep -oE '\${[A-Z_]*_TAG.*}' | \
        sort | \
        uniq | \
        sed -E 's/\$\{(.*_TAG):?-?(.*)}/\1=\2/' | \
        sed -E 's/(_TAG=)$/\1master-SNAPSHOT/')
    #Ensure we have a TAGS_FILE file, if not create one using the content of the defaultTags string
    if [ ! -f "${TAGS_FILE}" ]; then
        echo -e "Local configuration file (${BLUE}${TAGS_FILE}${NC}) doesn't exist so have created it with the following content"
        touch "${TAGS_FILE}"
        echo -e "$DEFAULT_TAGS_HEADER" > "${TAGS_FILE}"
        echo -e "$defaultTags" >> "${TAGS_FILE}"
        echo
        cat "${TAGS_FILE}"
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
    if [ ! -f "${file}" ]; then
        echo -e "${RED}File ${file} doesn't exist${NC}" >&2
        exit 1
    fi

    echo
    echo -e "Using file ${BLUE}${file}${NC} to resolve any docker tags and other variables"
    echo 

    if ${isDebugModeEnabled}; then
        #These lines can be used for debugging what env vars are being exported
        echo -e "${LGREY}Using the following environment variables${NC}"
        echo -e "${LGREY}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
        while read line; do
            if [[ "${line}" =~ ^[:space:]*[A-Z_]+= ]]; then
                echo -e "${DGREY}${line}${NC}"
            fi
        done < "${file}"
        echo -e "${LGREY}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    fi

    #Source the file, exporting all our env vars
    set -o allexport; source "${file}"; set +o allexport
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
            ip=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk 'NR==1{print $2}')
        else
            ip=$(ip route get 1 |awk 'match($0,"src [0-9\\.]+") {print substr($0,RSTART+4,RLENGTH-4)}')
        fi
        echo
        echo -e "Using IP ${GREEN}${ip}${NC} as the advertised host, as determined from the operating system"

        if [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo
            echo -e "${RED}ERROR${NC} IP address [${GREEN}${ip}${NC}] is not valid, try setting it manually i.e. '${BLUE}STROOM_RESOURCES_ADVERTISED_HOST=x.x.x.x ./bounceIt.sh ........${NC}'" >&2
            exit 1
        fi
    fi

    # This is used by the docker-compose YML files, so they can tell a browser where to go
    export STROOM_RESOURCES_ADVERTISED_HOST="${ip}"
    export HOST_IP="${ip}"
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
isDebugModeEnabled=false
#redirect stderr to /dev/null as running compose before we have exported env vars means we get a load
#of warnings about empty env vars. In this case we only want service names so don't care about stderr
allServices=$( \
    run_docker_compose_cmd config --services 2>/dev/null \
    | sort \
)
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

optspec=":def:hiyx"
while getopts "$optspec" optchar; do
    #echo "Parsing $optchar"
    case "${optchar}" in
        d)
            isDebugModeEnabled=true
            ;;
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
serviceNamesFromArgs=( "$@" )

if $useEnvironmentVariables && [ -n "$customEnvFile" ]; then
    echo -e "${RED}Cannot use -f and -e arguments together${NC}" >&2
    showUsage
    exit 1
fi

if [ -n "${customEnvFile}" ] && [ ! -f "${customEnvFile}" ]; then
    echo -e "${RED}File ${customEnvFile} does not exist${NC}" >&2
    exit 1
fi

# Check that the credentials file exists, if it doesn't create a default one
if [ ! -f ${CREDENTIALS_FILE} ]; then
    echo -e "Credentials File ${YELLOW}${CREDENTIALS_FILE}${NC} does not exist, creating a default one"

    cp "${DEFAULT_CREDENTIALS_FILE}" "${CREDENTIALS_FILE}"

    echo -e "Created default credentials in ${GREEN}${CREDENTIALS_FILE}${NC}, if you wish to customise the values, ensure they are edited before any containers are created"
fi
source ${CREDENTIALS_FILE}

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
if [ "${#SERVICE_LIST[@]}" -gt 0 ]; then
    serviceNames=( "${SERVICE_LIST[@]}" )
else
    serviceNames=()
fi

if [ "${#serviceNamesFromArgs[@]}" -gt 0 ]; then
    if [ "${#SERVICE_LIST[@]}" -gt 0 ]; then
        echo -e "Overriding service names from ${BLUE}SERVICE_LIST${NC}"
        echo -e "  [${GREEN}${SERVICE_LIST[*]}${NC}]"
        echo -e "with those from the command line"
        echo -e "  [${GREEN}${serviceNamesFromArgs[*]}${NC}]"
    fi
    serviceNames=( "${serviceNamesFromArgs[@]}" )
fi

if [ "${#serviceNames[@]}" -eq 0 ]; then
    echo
    echo -e "No service names specified, the COMPOSE_COMMAND [${GREEN}${composeCmd}${NC}] will be applied to all services" >&2

    #build a space delim list of services so we can later display all the images in use
    for service in $allServices; do
        serviceNames+=( "${service}" )
    done
else
    validServiceNameRegex=""
    for serviceName in ${allServices}; do
        validServiceNameRegex="${validServiceNameRegex}|${serviceName}"
    done

    #strip leading pipe char
    validServiceNameRegex=$(echo "$validServiceNameRegex" | sed -E 's/^\|//')
    validServiceNameRegex="(${validServiceNameRegex})"
    #echo -e "validServiceNameRegex: [${validServiceNameRegex}]"

    for serviceName in "${serviceNames[@]}"; do
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
        if [ "$(grep -c -e "^\s*127\.0\.0\.1\s*$host\s*$" /etc/hosts)" -eq 0 ]; then 
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
# This first line is a dry run so that we can see any errors
if ${isDebugModeEnabled}; then
    run_docker_compose_cmd config
fi

# Now capture the images by running the command again
allImages="$( \
    run_docker_compose_cmd config 2>/dev/null \
    | egrep "image: " \
)"

echo
echo "The following Docker services and tags will be used:"
echo

#print out all the services/images we are trying to use (i.e. potentially a subset of all those in the yml file
for serviceName in "${serviceNames[@]}"; do

    if ! egrep -q "^\s*${serviceName}:\s*$" "${YAML_FILES_DIR}"/**/*.yml; then
        echo
        echo -e "${RED}ERROR${NC} - Service ${GREEN}${serviceName}${NC} does" \
            "not exist in the yaml files in ${BLUE}${YAML_FILES_DIR}${NC}"
        exit 1
    else
        # The use of uniq is a bit of a hack to deal with the addition of the stroom-debug service 
        # (that shares the stroom image), therefore it outputs the same image twice for stroom.
        image=$( \
            echo "$allImages"  \
            | grep "${serviceName}:"  \
            | sed 's/.*image: //'  \
            | uniq \
        )
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
    for serviceName in "${serviceNames[@]}"; do
        #TODO this doesn't work for the likes of stroom-db because the image name is not the same
        #as the service name
        image=$(echo "$allImages" | grep "${serviceName}:" | sed 's/.*image: //')
        #echo "image: ${image}"

        #Ensure we have the latest image of stroom from dockerhub, unless our TAG contains LOCAL
        #Needed for floating tags like *-SNAPSHOT or v6

        #method to pull updated image files from dockerhub if required
        #This is to support -SNAPSHOT tags that are floating
        if [ "${image}x" != "x" ]; then
            if [[ "${image}" =~ .*(LOCAL).* ]]; then
                echo
                echo -e "${GREEN}${image}${NC} is a LOCAL image, DockerHub will " \
                    "not be checked for a new version"

            elif [[ "${image}" =~ .*(SNAPSHOT|LATEST|latest).* ]]; then
                #use 'docker-compose ps' to establish if we already have a container for this service
                #if we do then we won't do a docker-compose pull as that would trash any local state
                #if a user wants refreshed images from dockerhub then they should delete their containers first
                #using the dockerTidyUp script or similar
                existingContainerId="$( \
                    run_docker_compose_cmd \
                        ps \
                        -q \
                        "${serviceName}" \
                        2>/dev/null \
                    || echo ""
                )"
                if [ "x" = "${existingContainerId}x" ]; then
                    #no existing container so do a pull to check for updates
                    #If the image has a fixed tag version e.g. master-20171008-DAILY, then no change will be
                    #detected
                    echo
                    echo -e "Checking for any updates to the" \
                        "${GREEN}${serviceName}${NC} image on dockerhub"
                    run_docker_compose_cmd pull "${serviceName}"
                else
                    echo
                    echo -e "${GREEN}${serviceName}${NC} already has a" \
                        "container with ID ${BLUE}${existingContainerId}${NC}," \
                        "won't check dockerhub for updates"
                fi

            else
                echo
                echo -e "${GREEN}${image}${NC} is a fixed image, DockerHub" \
                    "will not be checked for a new version"
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
composeCmd="${composeCmd//${COMPOSE_CMD_DELIMITER}/ }"

echo
echo -e "Using command [${GREEN}${composeCmd}${NC}] against the following" \
    "services [${GREEN}${serviceNames[*]}${NC}]"
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

echo
echo -e "The following DropWizard admin pages will be available"
echo -e "  ${GREEN}stroom${NC}:${BLUE}       http://localhost:${STROOM_ADMIN_PORT}/stroomAdmin${NC}"
echo -e "  ${GREEN}stroom-stats${NC}:${BLUE} http://localhost:${STROOM_STATS_SERVICE_ADMIN_PORT}/statsAdmin${NC}"
echo -e "  ${GREEN}stroom-auth${NC}:${BLUE}  http://localhost:${STROOM_AUTH_SERVICE_ADMIN_PORT}/authenticationServiceAdmin${NC}"

if $requireConfirmation; then
    echo
    read -rsp $'Press [space|y|Y] to continue, or ctrl-c to exit... (you can use the \'-y\' argument to supress this confirmation prompt)\n' -n1 keyPressed

    if [[ "${keyPressed}X" =~ ^([:space:]|y|Y)?X$ ]] ; then
        echo
    else
        echo "Exiting"
        exit 0
    fi
fi

echo 
if $runStopCmdFirst; then
    echo "Ensuring ALL services are stopped"
    run_docker_compose_cmd stop 
fi

#pass any additional arguments after the yml filename direct to docker-compose
#This will create containers as required and then start up the new or existing containers
run_docker_compose_cmd \
    "${composeCmd}" \
    ${extraComposeArguments} \
    "${serviceNames[@]}"

exit 0

# vim: set tabstop=4 shiftwidth=4 expandtab:
