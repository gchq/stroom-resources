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

test_for_bash_version_4() {
  local -r bash_version="$(bash -c 'echo $BASH_VERSION')" 
  local -r bash_major_version="${bash_version:0:1}"
  if [[ "${bash_major_version}" -lt 4 ]]; then
    die "${RED}Error${NC}: Bash version 4 or higher required"
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
      "Incorrect number of arguments, expected ${expected_count}\n" \
      "Arguments [$*]"
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
      "Incorrect number of arguments, expected at least ${expected_min_count}\n" \
      "Arguments [$*]"
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
