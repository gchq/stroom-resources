#!/usr/bin/env bash

# Re-usable shell functions 


setup_echo_colours() {
  # Exit the script on any error
  set -e

  # shellcheck disable=SC2034
  if [ "${MONOCHROME}" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BLUE2=''
    NC='' # No Colour
  else 
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    BLUE2='\033[1;34m'
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

check_arg_count() {
  local expected_count="$1"
  local actual_count
  actual_count="$(( $# - 1 ))"

  if [[ "${actual_count}" -ne "${expected_count}" ]]; then
    die "${RED}ERROR${NC}: Incorrect number of arguments, expected ${expected_count}"
  fi
}

check_arg_count_at_least() {
  local expected_min_count="$1"
  local actual_count
  actual_count="$(( $# - 1 ))"

  if [[ "${actual_count}" -lt "${expected_min_count}" ]]; then
    die "${RED}ERROR${NC}: Incorrect number of arguments, expected at least ${expected_min_count}"
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
