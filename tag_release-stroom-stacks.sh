#!/usr/bin/env bash

# This script creates and pushes a git annotated tag with a commit message taken from
# the VERSIONS.txt file of a local stack build.
set -e

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
  msg="$*"
  echo -e "${RED}ERROR${GREEN}: ${msg}${NC}"
  echo
  exit 1
}

main() {
  local version="$1"
  # extract "v1.0.3" from "stroom_stacks-v1.0.3"
  local VERSION_PART="${version//stroom-stacks-/}"

  readonly STROOM_IMAGE_PREFIX='gchq/stroom'
  # Git tags should match this regex to be a release tag
  readonly RELEASE_VERSION_REGEX="^stroom-stacks-v[0-9]+\.[0-9]+.*$"
  readonly STACK_DIR="./bin/stack"
  readonly STACK_BUILD_DIR="${STACK_DIR}/build"
  readonly STACK_BUILD_SCRIPT="./build_ALL.sh"
  readonly STACK_DEFINITIONS_DIR="${STACK_DIR}/stack_definitions"

  setup_echo_colours
  echo

  if [ $# -ne 1 ]; then
    echo -e "${RED}ERROR${GREEN}: Missing version argument${NC}"
    echo -e "${GREEN}Usage: ${BLUE}./tag_release.sh version${NC}"
    echo -e "${GREEN}e.g:   ${BLUE}./tag_release.sh stroom-stacks-v6.0-beta.20${NC}"
    echo
    echo -e "${GREEN}This script will build all the stack variants and create an annotated git commit using the${NC}"
    echo -e "${GREEN}version information for each stack. The tag commit will be pushed to the origin.${NC}"
    exit 1
  fi


  if [[ ! "${version}" =~ ${RELEASE_VERSION_REGEX} ]]; then
    error_exit "Version [${BLUE}${version}${GREEN}] does not match the" \
      "release version regex ${BLUE}${RELEASE_VERSION_REGEX}${NC}"
  fi

  if ! git rev-parse --show-toplevel > /dev/null 2>&1; then
    error_exit "You are not in a git repository. This script should be run" \
      "from the root of a repository.${NC}"
  fi

  if git tag | grep -q "^${version}$"; then
    error_exit "This repository has already been tagged with" \
      "[${BLUE}${version}${GREEN}].${NC}"
  fi

  if [ "$(git status --porcelain 2>/dev/null | wc -l)" -ne 0 ]; then
    error_exit "There are uncommitted changes or untracked files. Commit them" \
      "before tagging.${NC}"
  fi

  if [ ! -f "${STACK_DIR}/${STACK_BUILD_SCRIPT}" ]; then
    error_exit "The stack build script ${BLUE}${STACK_DIR}/${STACK_BUILD_SCRIPT}${NC} does not exist.${NC}"
  fi

  if [ -d "${STACK_BUILD_DIR}" ]; then
    error_exit "The stack build directory" \
      "${BLUE}${STACK_BUILD_DIR}${NC} already exists. Please delete it.${NC}"
  fi

  echo -e "${GREEN}Running local stack build to capture docker image versions${NC}"
  echo
  echo -e "${BLUE}--------------------------------------------------------------------------------${NC}"

  pushd "${STACK_DIR}" > /dev/null

  # Run the stacks build to make sure it works locally before tagging and
  # to capture the docker image version info
  "${STACK_BUILD_SCRIPT}" "${VERSION_PART}"

  echo
  echo -e "${BLUE}--------------------------------------------------------------------------------${NC}"
  echo

  popd > /dev/null

  # Get the names of all the stacks in the build
  local stack_names
  stack_names="$( \
    find  \
    "${STACK_DEFINITIONS_DIR}" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -printf '%f\n'
  )"

  local commit_msg="${version}\n\n"
  commit_msg+="The following stacks are in this release. Each stack lists the\n"
  commit_msg+="docker image versions used.\n\n"

  for stack_name in ${stack_names}; do
    local versions_file="${STACK_BUILD_DIR}/${stack_name}/${stack_name}-${VERSION_PART}/VERSIONS.txt"
    if [ ! -f "${versions_file}" ]; then
      error_exit "Can't find file ${BLUE}${versions_file}${GREEN} in the stack build${NC}"
    fi

    if grep -qi "SNAPSHOT" "${versions_file}"; then
      error_exit "Found a ${BLUE}SNAPSHOT${GREEN} version in the" \
        "${BLUE}${versions_file}${GREEN} file. You can't release a SNAPSHOT"
    fi

    # If the stack includes stroom, make sure the stroom image matches the version
    if grep -q "${STROOM_IMAGE_PREFIX}:" "${versions_file}"; then
      # Extract the version part of the tag, e.g. v6.0-beta.20
      local stroom_version="v${version#*-v}"
      # Get the full stroom docker image tag from the VERSIONS.txt file
      local stroom_image_tag
      stroom_image_tag="$(grep "${STROOM_IMAGE_PREFIX}:.*" "${versions_file}")"
      # Extract the version part of the stroom tag
      local stroom_image_version="${stroom_image_tag#*:}"

      if ! echo "${stroom_version}" | grep -q "${stroom_image_version}"; then
        error_exit "Expecting the git tag [${BLUE}${version}${GREEN}] to include" \
          "the stroom image version [${BLUE}${stroom_image_version}${GREEN}] in it.${NC}"
      fi
    fi

    commit_msg+="${stack_name}\n"
    commit_msg+="===========================\n"
    commit_msg+="$(<"${versions_file}")\n\n"
  done

  # Remove any repeated blank lines with cat -s
  commit_msg="$(echo -e "${commit_msg}" | cat -s)"

  echo -e "${DGREY}------------------------------------------------------------------------${NC}"
  echo -e "${YELLOW}${commit_msg}${NC}"
  echo -e "${DGREY}------------------------------------------------------------------------${NC}"
  echo
  echo -e "${GREEN}You are about to create the git tag" \
    "${BLUE}${version}${GREEN} with the above commit message text.${NC}"

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
