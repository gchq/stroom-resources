#!/usr/bin/env bash 

SUPPORTED_COMPOSE_CMDS_REGEX="(start|stop|restart|up|down)"
DEFAULT_COMPOSE_CMD="up"
upWithBuildOption=false
requireConfirmation=false
useEnvironmentVariables=false

showUsage() {
    echo "Usage: $0 [COMPOSE_COMMAND] [OPTIONS] [--build] [SERVICE_NAME...]"
    echo "COMPOSE_COMMAND - One of $SUPPORTED_COMPOSE_CMDS_REGEX, if not supplied \"$DEFAULT_COMPOSE_CMD\" will be used"
    echo "Options:"
    echo "  -h - Show this help text"
    echo "  -e - Rely on existing environment variables for any docker tags, the docker.tags file will not be used"
    echo "  -y - Do not prompt for confirmation, e.g. when run from a script"
    echo "e.g.: $0 "
}

if [[ "$1" =~ $SUPPORTED_COMPOSE_CMDS_REGEX ]]; then
    composeCmd=$1
    #shift the args by one, discarding the one we have just read
    shift
else
    composeCmd="$DEFAULT_COMPOSE_CMD"
fi

optspec=":hye-:"
#The following code to parse long args, e.g. --build, is derived from an answer in
#https://stackoverflow.com/questions/402377/using-getopts-in-bash-shell-script-to-get-long-and-short-command-line-options
while getopts "$optspec" optchar; do
    echo "Parsing $optchar"
    case "${optchar}" in
        -)
            #This is a long arg like --some-long-arg
            case "${OPTARG}" in
                build)
                    upWithBuildOption=true
                    #echo "Using upWithBuildOption" >&2;
                    ;;
                *)
                    echo "Unknown option --${OPTARG}" >&2
                    echo
                    showUsage
                    exit 2
                    ;;
            esac;;
        h)
            #help
            showUsage
            exit 1
            ;;
        e)
            #echo "Parsing option: '-${optchar}'" >&2
            echo "Using environment variables"
            useEnvironmentVariables=true
            ;;
        y)
            #echo "Parsing option: '-${optchar}'" >&2
            echo "Will not prompt for confirmation"
            requireConfirmation=true
            ;;
        *)
            echo "Unknown argument: '-${OPTARG}'" >&2
            echo
            showUsage
            exit 1
            ;;
    esac
done

#discard the args parsed so far
shift $((OPTIND -1))

echo "Remaining args: $@"
serviceNames="$@"

for serviceName in $serviceNames; do
    #echo "  Service: [${serviceName}]"
    if [[ "${serviceName}" =~ ^-.* ]]; then
        echo "OPTIONS must be specified before SERVICE_NAMEs" >&2
        echo
        showUsage
        exit 1
    fi
done


echo "composeCmd: $composeCmd"
echo "upWithBuildOption: $upWithBuildOption"
echo "requireConfirmation: $requireConfirmation"
echo "useEnvironmentVariables: $useEnvironmentVariables"
