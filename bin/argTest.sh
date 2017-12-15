#!/usr/bin/env bash 

SUPPORTED_COMPOSE_CMDS_REGEX="(start|stop|restart|up|down)"
DEFAULT_COMPOSE_CMD="up"
composeCmd=$1
upWithBuildOption=false

if [[ "$composeCmd" =~ $SUPPORTED_COMPOSE_CMDS_REGEX ]]; then
    #shift the args by one, discarding the one we have just read
    shift
else
    composeCmd="$DEFAULT_COMPOSE_CMD"
fi


optspec=":hyve-:"
#The following code to parse long args, e.g. --build, is derived from an answer in
#https://stackoverflow.com/questions/402377/using-getopts-in-bash-shell-script-to-get-long-and-short-command-line-options
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                build)
                    upWithBuildOption=true
                    echo "Using upWithBuildOption" >&2;
                    ;;
                *)
                    echo "Unknown option --${OPTARG}" >&2
                    exit 2
                    ;;
            esac;;
        h)
            echo "usage: $0 [-v] [--loglevel[=]<value>]" >&2
            exit 2
            ;;
        e)
            echo "Parsing option: '-${optchar}'" >&2
            echo "Using environment variables"
            ;;
        y)
            echo "Parsing option: '-${optchar}'" >&2
            echo "Will not prompt for confirmation"
            ;;
        *)
            echo "Non-option argument: '-${OPTARG}'" >&2
            ;;
    esac
done

echo "composeCmd: $composeCmd"
