#!/usr/bin/env bash

set -e

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

error_exit() {
  msg="$*"
  echo -e "${RED}ERROR${GREEN}: ${msg}${NC}"
  echo
  exit 1
}

debug_value() {
  local name="$1"; shift
  local value="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${name}: ${value}${NC}"
  fi
}

debug() {
  local str="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${str}${NC}"
  fi
}

main() {
  IS_DEBUG=false
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

  setup_echo_colours

  if [ $# -ne 1 ]; then
    echo -e "${RED}ERROR${GREEN}: Missing version argument${NC}"
    echo -e "${GREEN}Usage: ${BLUE}./uplift_stroom.sh stroom_version${NC}"
    echo -e "${GREEN}e.g:   ${BLUE}./uplift_stroom.sh v6.0-beta.20${NC}"
    echo
    echo -e "${GREEN}This script will uplift the stroom version in the container_versions file${NC}"
    echo -e "${GREEN}and commit the change.${NC}"
    exit 1
  fi

  local stroom_version="$1"
  repo_root="$(git rev-parse --show-toplevel)"
  local repo_root
  debug "repo_root: ${repo_root}"
  # Switch to the repo root so all git commands are run from there
  pushd "${repo_root}" > /dev/null

  local build_dir="${repo_root}/bin/stack/build"
  local container_versions_file="${repo_root}/bin/stack/container_versions.env"

  echo -e "${GREEN}Deleting build directory ${BLUE}${build_dir}${NC}"
  rm -rf "${build_dir}"

  # Uplift the stroom version in the 
  perl \
    -0777 \
    -i \
    -pe \
    "s/(?<=STROOM_TAG=\")([^\"]+)(?=\")/${stroom_version}/" \
    "${container_versions_file}"

  
  if git diff --quiet "${container_versions_file}"; then
    echo -e "${GREEN}There are no changes to the local respository${NC}"
    echo -e "${GREEN}Something may have gone wrong${NC}"
    exit 0
  else
    echo
    git --no-pager diff "${container_versions_file}"

    echo
    read -rsp $'Press "y" to commit this change, any other key to cancel.\n' -n1 keyPressed
    echo
    if [ "$keyPressed" = 'y' ] || [ "$keyPressed" = 'Y' ]; then
      git add "${container_versions_file}"
      git commit -m "Uplifting STROOM_TAG to ${stroom_version}"
      git push
      echo -e "${GREEN}Done.${NC}"
    fi
  fi
}

main "$@"
