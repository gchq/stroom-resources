#!/usr/bin/env bash 


#Colour constants for use in echo -e statements
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Colour


SUPPORTED_COMPOSE_CMDS_REGEX="(start|stop|restart|up|down)"
DEFAULT_COMPOSE_CMD="up"
requireConfirmation=false
requireHostFileCheck=true
useEnvironmentVariables=false

showUsage() {
    echo "Usage: $0 [COMPOSE_COMMAND] [OPTION]... [EXTRA_COMPOSE_ARG]... [SERVICE_NAME]..."
    echo "COMPOSE_COMMAND - One of ${SUPPORTED_COMPOSE_CMDS_REGEX}, if not supplied \"${DEFAULT_COMPOSE_CMD}\" will be used"
    echo "OPTIONs:"
    echo "  -h - Show this help text"
    echo "  -e - Rely on existing environment variables for any docker tags, the docker.tags file will not be used"
    echo "  -x - Do not check hosts file for docker related entries"
    echo "  -y - Do not prompt for confirmation, e.g. when run from a script"
    echo "EXTRA_COMPOSE_ARGs - Any additional arguments for docker-compose, of the form \"--argName\", e.g. \"--build\""
    echo "e.g.: $0 serviceX serviceY"
    echo "e.g.: $0 up -e -y --build --verbose serviceX serviceY"
}

if [[ "$1" =~ $SUPPORTED_COMPOSE_CMDS_REGEX ]]; then
    composeCmd=$1
    #shift the args by one, discarding the one we have just read
    shift
else
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
            requireConfirmation=true
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

if [ $# = 0 ]; then
    echo -e "${RED}No SERVICE_NAMEs specified${NC}" >&2
    showUsage
    exit 1
fi

#echo "Remaining args: $@"
serviceNames="$@"

for serviceName in $serviceNames; do
    #echo "  Service: [${serviceName}]"
    if [[ "${serviceName}" =~ ^-.* ]]; then
        echo -e "${RED}OPTIONS must be specified before SERVICE_NAMEs${NC}" >&2
        echo
        showUsage
        exit 1
    fi
done

#echo "requireConfirmation: $requireConfirmation"
#echo "useEnvironmentVariables: $useEnvironmentVariables"

#strip any leading whitespace
extraComposeArguments=$(echo "$extraComposeArguments" | sed -r 's/\s//')

echo -e "Using command [${GREEN}${composeCmd}${NC}] with additional arguments [${GREEN}${extraComposeArguments}${NC}] against the following services [${GREEN}${serviceNames}${NC}]"

if $useEnvironmentVariables ; then
    echo "Using environment variables to resolve any docker tag variables"
else
    echo -e "Using ${BLUE}docker.tags${NC} file to resolve any docker tag variables"
fi

exit 0
