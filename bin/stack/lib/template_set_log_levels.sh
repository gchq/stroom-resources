#!/bin/bash

############################################################################
# 
#  Copyright 2019 Crown Copyright
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# 
############################################################################

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script to change the log level of multiple class/packages
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set -e

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
{
  source "$DIR"/lib/shell_utils.sh
}

# This line MUST be before we source the env file, as HOST_IP may be set
# in the env file and thus needs to override the HOST_IP determined here.
# shellcheck disable=SC2034
HOST_IP=$(determine_host_address)

# Read the file containing all the env var exports to make them
# available to docker-compose
# shellcheck disable=SC1090
source "$DIR"/config/<STACK_NAME>.env

#Shell Colour constants for use in 'echo -e'
#e.g.  echo -e "My message ${GREEN}with just this text in green${NC}"
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Colour 

readonly URL="http://127.0.0.1:8081/admin/tasks/log-level"
readonly CURL="curl"
readonly HTTPIE="http"

send_request() {
    packageOrClass=$1
    newLogLevel=$2

    echo -e "Setting ${GREEN}${packageOrClass}${NC} to ${GREEN}${newLogLevel}${NC}"
    echo

    if [ "${binary}" = "${HTTPIE}" ]; then
        ${HTTPIE} --headers -f POST ${URL} logger="${packageOrClass}" level="${newLogLevel}"
    else
        ${CURL} -X POST -d "logger=${packageOrClass}&level=${newLogLevel}" ${URL}
    fi
}

main() {

    if ! [ -x "$(command -v http > /dev/null)" ]; then
        echo -e "${YELLOW}WARN${NC} - ${BLUE}httpie${NC} is not installed" \
          "(see ${BLUE}https://httpie.org${NC})," \
          "falling back to ${BLUE}curl${NC}." >&2
        echo
        binary="${CURL}"
    else
        binary="${HTTPIE}"
    fi

    # should have an arg count that is a multiple of two
    if [ $# -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
        echo -e "${RED}ERROR${NC} - Invalid arguments" >&2
        echo -e "Usage: ${BLUE}$0${GREEN} packageOrClass1 newLogLevel packageOrClassN newLogLevel ...${NC}" >&2
        echo -e "e.g:   ${BLUE}$0${GREEN} stroom.startup.App DEBUG stroom.startup.Config TRACE${NC}" >&2
        exit 1
    fi

    echo -e "Using URL ${BLUE}${URL}${NC}"
    echo

    #loop through the pairs of args
    while [ $# -gt 0 ]; do
        packageOrClass="$1"
        newLogLevel="$2"

        send_request "${packageOrClass}" "${newLogLevel}"

        #bin the two args we have just used
        shift 2
    done

    echo "${GREEN}Done${NC}"
}

main "$@"
