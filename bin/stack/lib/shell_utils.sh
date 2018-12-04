#!/usr/bin/env bash
#
# shellcheck disable=SC2034
#
# Re-usable shell functions 


setup_echo_colours() {
    # Exit the script on any error
    set -e

    #Shell Colour constants for use in 'echo -e'
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    LGREY='\e[37m'
    DGREY='\e[90m'
    NC='\033[0m' # No Color
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
        die "${RED}ERROR${NC}: Incorrect number of arguments"
    fi
}
