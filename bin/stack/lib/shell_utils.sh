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

# Needed for ERR trap to work
set -o errtrace

# Array to hold any temp files to clean up at the end
# e.g. tempfiles+=( "$my_temp_file" )
tempfiles=( )

cleanup() {
  rm -f "${tempfiles[@]}"
}

# Code adapted from https://stackoverflow.com/questions/64786/error-handling-in-bash
unexpected_error() {

  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo -e "${RED}Error${NC}: Script failed on or near line" \
      "${BLUE}${parent_lineno}${NC}:" \
      "${BLUE}${message}${NC}; exiting with status ${BLUE}${code}${NC}"
  else
    echo -e "${RED}Error${NC}: Script failed on or near line" \
      "${BLUE}${parent_lineno}${NC};" \
      "exiting with status ${BLUE}${code}${NC}"
  fi
  #dump_call_stack
  exit "${code}"
}

ctrl_c() {
  echo -e "Script cancelled by user!"
  exit 1
}

trap 'unexpected_error ${LINENO}' ERR

trap ctrl_c SIGINT
trap ctrl_c SIGTERM

# Run cleanup on successful exit
trap cleanup 0

# Re-usable shell functions 

setup_echo_colours() {
  # shellcheck disable=SC2034
  if [ "${MONOCHROME}" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BLUE2=''
    DGREY=''
    NC='' # No Colour
  else 
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    BLUE2='\033[1;34m'
    DGREY='\e[90m'
    NC='\033[0m' # No Colour
  fi
}

err() {
  echo -e "$@" >&2
}

die () {
  echo -e "$@" >&2
  exit 1
}

debug() {
  if [ "${IS_DEBUG_ENABLED}" = true ]; then
    echo -e "${YELLOW}DEBUG${NC}: $*"
  fi
}

debug_arguments() {
  if [ "${IS_DEBUG_ENABLED}" = true ]; then
    debug "${FUNCNAME[1]}() called with [$*]"
  fi
}

test_for_bash_version_4() {
  local -r bash_version="$(bash -c 'echo $BASH_VERSION')" 
  local -r bash_major_version="${bash_version:0:1}"
  if [[ "${bash_major_version}" -lt 4 ]]; then
    die "${RED}Error${NC}: Bash version 4 or higher required"
  fi
}

check_binary_is_available() {
  local binary_name="$1"
  if ! command -v "${binary_name}" 1>/dev/null; then
    die "${RED}Error${NC}:  ${BLUE}${binary_name}${NC} is not installed." \
      "Please install it and try again"
  fi
}

dump_call_stack () {
  local stack_length=${#FUNCNAME[@]}
  local last_idx=$(( stack_length - 1 ))
  local i=0
  local indent=""
  echo "${indent}Function call stack ( script - function() ) ..." >&2
  while (( i <= last_idx )); do
    indent="${indent}  "
    local script_name
    script_name="$(basename "${BASH_SOURCE[$i]}")"
    if [ "$i" == "${last_idx}" ]; then
      # bash calls the top level function main() so don't print that
      # to avoid confusion with our main() function
      echo "${indent}${script_name}" >&2
    else
      echo "${indent}${script_name} - ${FUNCNAME[$i]}()" >&2
    fi
    # if expr evaluates to zero it returns a non-zero code
    (( i++ )) || true
  done
}

check_arg_count() {
  local expected_count="$1"
  local actual_count
  actual_count="$(( $# - 1 ))"

  if [[ "${actual_count}" -ne "${expected_count}" ]]; then
    echo -e "${RED}ERROR${NC}:" \
      "Incorrect number of arguments, expected ${expected_count}." \
      "Arguments passed: [${*:2}]"
    dump_call_stack
    exit 1
  fi
}

check_arg_count_at_least() {
  local expected_min_count="$1"
  local actual_count
  actual_count="$(( $# - 1 ))"

  if [[ "${actual_count}" -lt "${expected_min_count}" ]]; then
    echo -e "${RED}ERROR${NC}:" \
      "Incorrect number of arguments, expected at least ${expected_min_count}" \
      "Arguments passed: [${*:2}]"
    dump_call_stack
    exit 1
  fi
}

# Returns 0 if $1 is in the array of elements passed as subsequent args
# e.g. 
# arr=( "one" "two" "three" )
# element_in "two" "${arr[@]}" # returns 0
element_in () {
  local element 
  local match="$1"
  shift
  for element; do 
    [[ "${element}" == "${match}" ]] && return 0
  done
  return 1
}
