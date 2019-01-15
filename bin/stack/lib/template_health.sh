#!/usr/bin/env bash
#
# Checks the health of each app using the supplied admin url

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh
source "$DIR"/lib/stroom_utils.sh

# leading colon means silent error reporting by getopts
while getopts ":m" arg; do
  # shellcheck disable=SC2034
  case $arg in
    m )  
      MONOCHROME=true 
      ;;
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

setup_echo_colours

# Read the file containing all the env var exports so we can test
# if certain port variables are set or not
source "$DIR"/config/<STACK_NAME>.env

check_overall_health

# return the unhealthy count so this script can be used in an automated way
exit $?
