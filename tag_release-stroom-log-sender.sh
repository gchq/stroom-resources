#!/usr/bin/env bash

# This script creates and pushes a git annotated tag with a commit message taken from
# the appropriate section of the CHANGELOG.md.
set -e

# Git tags should match this regex to be a release tag
readonly RELEASE_VERSION_REGEX='^stroom-log-sender-v[0-9]+\.[0-9]+.*$'
readonly EXAMPLE_TAG='stroom-log-sender-v6.0-beta.1'
readonly CHANGELOG_FILE='CHANGELOG.md'

setup_echo_colours() {
  #Shell Colour constants for use in 'echo -e'
  # shellcheck disable=SC2034
  {
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    LGREY='\e[37m'
    DGREY='\e[90m'
    NC='\033[0m' # No Color
  }
}

error_exit() {
  msg="$1"
  echo -e "${RED}ERROR${GREEN}: ${msg}${NC}"
  echo
  exit 1
}

show_usage() {
  local script_name
  script_name="$(basename "$0")"
  {
    echo -e "${RED}ERROR${GREEN}: Missing version argument${NC}"
    echo -e "${GREEN}Usage: ${BLUE}./${script_name} version${NC}"
    echo -e "${GREEN}e.g:   ${BLUE}./${script_name} ${EXAMPLE_TAG}${NC}"
    echo
    echo -e "${GREEN}This script will create an annotated git tag. The tag commit will be pushed${NC}"
    echo -e "${GREEN}to the origin.${NC}"
  } >&2
  exit 1
}

main() {
  setup_echo_colours
  echo

  if [ $# -ne 1 ]; then
    show_usage
  fi

  local version=$1

  if [[ ! "${version}" =~ ${RELEASE_VERSION_REGEX} ]]; then
    error_exit "Version [${BLUE}${version}${GREEN}] does not match the release version regex ${BLUE}${RELEASE_VERSION_REGEX}${NC}"
  fi

  if ! git rev-parse --show-toplevel > /dev/null 2>&1; then
    error_exit "You are not in a git repository. This script should be run from the root of a repository.${NC}"
  fi

  if git tag | grep -q "^${version}$"; then
    error_exit "This repository has already been tagged with [${BLUE}${version}${GREEN}].${NC}"
  fi

  if [ "$(git status --porcelain 2>/dev/null | wc -l)" -ne 0 ]; then
    error_exit "There are uncommitted changes or untracked files. Commit them before tagging.${NC}"
  fi

  local commit_msg
  # Add the release version as the top line of the commit msg
  commit_msg="${version}"

  echo -e "${GREEN}You are about to create the git tag ${BLUE}${version}${NC}"

  read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

  if [ "$keyPressed" = 'y' ] || [ "$keyPressed" = 'Y' ]; then
    echo
    echo -e "${GREEN}Tagging the current commit${NC}"
    echo -e "${commit_msg}" | git tag -a --file - "${version}"

    echo -e "${GREEN}Pushing the new tag${NC}"
    git push origin "${version}"

    echo -e "${GREEN}Done.${NC}"
    echo
  else
    echo
    echo -e "${GREEN}Exiting without tagging a commit${NC}"
    echo
    exit 0
  fi
}

main "$@"
