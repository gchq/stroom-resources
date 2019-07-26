#!/usr/bin/env bash

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

# Sends data to stroom or stroom-proxy

set -e

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR:-.}"/lib/shell_utils.sh
source "${DIR:-.}"/lib/stroom_utils.sh
source "${DIR:-.}"/lib/constants.sh

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

readonly VALID_DESTINATIONS="stroom|stroom-proxy"

check_destination() {
  if ! is_service_in_stack "${destination}"; then
    die "${RED}Error:${GREEN}" \
      "Invalid destination. ${BLUE}${destination}${NC} is not part of the stack"
  fi
}

show_usage() {
  echo -e "Usage: ${BLUE}$(basename "$0") data-directory destination(${VALID_DESTINATIONS}) feed-name system-name environment${NC}" >&2
  echo -e "This script will send all files contained in data-directory to the destination system."
  echo -e "All files successfully sent will be deleted. It does not recurse into child directories."
  echo -e "Valid OPTION values:"
  echo -e "  -m   Use monochrome output, coloured output is used by default."
  echo -e "  -h   Display this help"
  echo -e "E.g.:  ${BLUE}$0 /tmp/data stroom-proxy TEST_FEED MY_TEST_SYSTEM DEV${NC}" >&2
}

main() {

  local -r data_dir="$1"
  local -r destination="$2"
  local -r feed_name="$3"
  local -r system_name="$4"
  local -r environment="$5"

  #echo -e "${GREEN}Sending data in ${BLUE}${data_dir}${GREEN} to ${BLUE}${destination}${GREEN}" \
  #" with feed: ${BLUE}${feed_name}${GREEN}" \
  #", system: ${BLUE}${system_name}${GREEN}" \
  #" and environment: ${BLUE}${environment}${NC}"

  check_destination "${destination}"

  if [ "${destination}" = "stroom" ]; then
    local port=443
  elif [ "${destination}" = "stroom-proxy-local" ]; then
    local port
    port="$(get_config_env_var "STROOM_PROXY_HTTPS_APP_PORT")"
  else
    die "${RED}Error:${GREEN}" \
      "invalid destination ${BLUE}${destination}${NC}, should be one of" \
      "(${BLUE}${VALID_DESTINATIONS}${NC}${GREEN})${NC}"
  fi

  local url=https://localhost:${port}/stroom/datafeed

  if [ ! -d "${data_dir}" ]; then
    die "${RED}ERROR:${GREEN} data directory ${BLUE}${data_dir}${GREEN} does not exist${NC}"
  fi

  if [ "${MONOCHROME}" = true ]; then
    local pretty_arg="--no-pretty"
  else
    local pretty_arg="--pretty"
  fi

  "${DIR:-.}"/lib/send_to_stroom.sh \
    --no-secure \
    "${pretty_arg}" \
    --file-regex ".*/.*" \
    --key ./certs/client.unencrypted.key \
    --cert ./certs/client.pem.crt \
    --cacert ./certs/ca.pem.crt \
    "${data_dir}" \
    "${feed_name}" \
    "${system_name}" \
    "${environment}" \
    "${url}"
}

# ~~~ Script starts here ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

# leading colon means silent error reporting by getopts
while getopts ":hm" arg; do
  case $arg in
    h )  
      show_usage
      exit 0
      ;;
    m )  
      # shellcheck disable=SC2034
      MONOCHROME=true 
      ;;
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

setup_echo_colours

required_arg_count=5
if [ $# -ne ${required_arg_count} ]; then
  echo -e "${RED}Error${NC}: Invalid arguments, found $# args, required ${required_arg_count}" >&2
  show_usage
  exit 1
fi

main "$@"
