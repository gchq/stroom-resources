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
    msg="$1"
    echo -e "${RED}ERROR${GREEN}: ${msg}${NC}"
    echo
    exit 1
}

main() {
    readonly STACK_NAME='stroom_core'
    readonly STROOM_IMAGE_PREFIX='gchq/stroom'
    # Git tags should match this regex to be a release tag
    readonly RELEASE_VERSION_REGEX="^${STACK_NAME}-v[0-9]+\.[0-9]+.*$"
    readonly STACK_DIR="./bin/stack"
    readonly STACK_BUILD_DIR="${STACK_DIR}/build"
    readonly STACK_BUILD_SCRIPT="./build${STACK_NAME}.sh"
    readonly VERSIONS_FILE="${STACK_BUILD_DIR}/${STACK_NAME}/${STACK_NAME}-SNAPSHOT/VERSIONS.txt"

    setup_echo_colours
    echo

    if [ $# -ne 1 ]; then
        echo -e "${RED}ERROR${GREEN}: Missing version argument${NC}"
        echo -e "${GREEN}Usage: ${BLUE}./tag_release.sh version${NC}"
        echo -e "${GREEN}e.g:   ${BLUE}./tag_release.sh stroom_core-v6.0-beta.20${NC}"
        echo
        echo -e "${GREEN}This script will build a local stack and create an annotated git commit using the${NC}"
        echo -e "${GREEN}VERSIONS.txt file content. The tag commit will be pushed to the origin.${NC}"
        exit 1
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

    if [ -d "${STACK_BUILD_DIR}" ]; then
        error_exit "The stack build directory ${BLUE}${STACK_BUILD_DIR}${NC} already exists. Please delete it.${NC}"
    fi

    echo -e "${GREEN}Running local stack build to capture docker image versions${NC}"
    echo
    echo -e "${BLUE}--------------------------------------------------------------------------------${NC}"

    pushd "${STACK_DIR}" > /dev/null

    "${STACK_BUILD_SCRIPT}"

    echo
    echo -e "${BLUE}--------------------------------------------------------------------------------${NC}"
    echo

    popd > /dev/null

    if [ ! -f "${VERSIONS_FILE}" ]; then
        error_exit "Can't find file ${BLUE}${VERSIONS_FILE}${GREEN} in the stack build${NC}"
    fi

    if grep -q "SNAPSHOT" "${VERSIONS_FILE}"; then
        error_exit "Found a ${BLUE}SNAPSHOT${GREEN} version in the ${BLUE}VERSIONS.txt${GREEN} file. You can't release a SNAPSHOT"
    fi

    # Extract the version part of the tag, e.g. v6.0-beta.20
    local stroom_version="v${version#*-v}"
    # Get the full stroom docker image tag from the VERSIONS.txt file
    local stroom_image_tag
    stroom_image_tag="$(grep "${STROOM_IMAGE_PREFIX}:.*" "${VERSIONS_FILE}")"
    # Extract the version part of the stroom tag
    local stroom_image_version="${stroom_image_tag#*:}"

    if ! echo "${stroom_version}" | grep -q "${stroom_image_version}"; then
        error_exit "Expecting the git tag [${BLUE}${version}${GREEN}] to include the stroom image version [${BLUE}${stroom_image_version}${GREEN}] in it.${NC}"
    fi

    local commit_msg

    commit_msg="$(cat ${VERSIONS_FILE})"

    # Add the release version as the top line of the commit msg, followed by
    # two new lines
    commit_msg="${version}\n\n${commit_msg}"

    # Remove any repeated blank lines with cat -s
    commit_msg="$(echo -e "${commit_msg}" | cat -s)"

    echo -e "${GREEN}You are about to create the git tag ${BLUE}${version}${GREEN} with the following commit message.${NC}"
    echo -e "${DGREY}------------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}${commit_msg}${NC}"
    echo -e "${DGREY}------------------------------------------------------------------------${NC}"

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
