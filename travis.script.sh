#!/bin/bash

#exit script on any error
set -e

#Shell Colour constants for use in 'echo -e'
#e.g.  echo -e "My message ${GREEN}with just this text in green${NC}"
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Colour 

TAG_PREFIX_STROOM_NGINX="stroom-nginx"
TAG_PREFIX_STROOM_STROOM_CORE="stroom_core"
TAG_PREFIX_STROOM_STROOM_FULL="stroom_full"

DOCKER_REPO_STROOM_NGINX="gchq/stroom-nginx"
DOCKER_CONTEXT_ROOT_STROOM_NGINX="stroom-nginx/."

VERSION_FIXED_TAG=""
SNAPSHOT_FLOATING_TAG=""
MAJOR_VER_FLOATING_TAG=""
MINOR_VER_FLOATING_TAG=""
VERSION_PART_REGEX='v[0-9]+\.[0-9]+.*$'
RELEASE_VERSION_REGEX="^.*-${VERSION_PART_REGEX}"
LATEST_SUFFIX="-LATEST"

#args: dockerRepo contextRoot tag1VersionPart tag2VersionPart ... tagNVersionPart
release_to_docker_hub() {
    #echo "releaseToDockerHub called with args [$@]"

    if [ $# -lt 3 ]; then
        echo "Incorrect args, expecting at least 3"
        exit 1
    fi
    dockerRepo="$1"
    contextRoot="$2"
    #shift the the args so we can loop round the open ended list of tags, $1 is now the first tag
    shift 2

    allTagArgs=""

    for tagVersionPart in "$@"; do
        if [ "x${tagVersionPart}" != "x" ]; then
            #echo -e "Adding docker tag [${GREEN}${tagVersionPart}${NC}]"
            allTagArgs="${allTagArgs} --tag=${dockerRepo}:${tagVersionPart}"
        fi
    done

    echo -e "Building and releasing a docker image using:"
    echo -e "dockerRepo:                    [${GREEN}${dockerRepo}${NC}]"
    echo -e "contextRoot:                   [${GREEN}${contextRoot}${NC}]"
    echo -e "allTags:                       [${GREEN}${allTagArgs}${NC}]"

    docker build ${allTagArgs} ${contextRoot}

    #The username and password are configured in the travis gui
    echo -e "Logging in to DockerHub"
    docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" >/dev/null 2>&1

    docker build ${allTagArgs} ${contextRoot} >/dev/null 2>&1
    echo -e "Pushing to DockerHub"
    #docker push ${dockerRepo} >/dev/null 2>&1
}

derive_docker_tags() {
    #This is a tagged commit, so create a docker image with that tag
    VERSION_FIXED_TAG="${BUILD_VERSION}"

    #Extract the major version part for a floating tag
    majorVer=$(echo "${BUILD_VERSION}" | grep -oP "^v[0-9]+")
    if [ -n "${majorVer}" ]; then
        MAJOR_VER_FLOATING_TAG="${majorVer}${LATEST_SUFFIX}"
    fi

    #Extract the minor version part for a floating tag
    minorVer=$(echo "${BUILD_VERSION}" | grep -oP "^v[0-9]+\.[0-9]+")
    if [ -n "${minorVer}" ]; then
        MINOR_VER_FLOATING_TAG="${minorVer}${LATEST_SUFFIX}"
    fi

    echo -e "VERSION FIXED DOCKER TAG:      [${GREEN}${VERSION_FIXED_TAG}${NC}]"
    echo -e "MAJOR VER FLOATING DOCKER TAG: [${GREEN}${MAJOR_VER_FLOATING_TAG}${NC}]"
    echo -e "MINOR VER FLOATING DOCKER TAG: [${GREEN}${MINOR_VER_FLOATING_TAG}${NC}]"

    #TODO - the major and minor floating tags assume that the release builds are all done in strict sequence
    #If say the build for v6.0.1 is re-run after the build for v6.0.2 has run then v6.0-LATEST will point to v6.0.1
    #which is incorrect, hopefully this course of events is unlikely to happen
    allDockerTags="${VERSION_FIXED_TAG} ${SNAPSHOT_FLOATING_TAG} ${MAJOR_VER_FLOATING_TAG} ${MINOR_VER_FLOATING_TAG}"
}

do_stack_build() {
    local -r scriptName="${1}.sh"
    local -r scriptDir=${TRAVIS_BUILD_DIR}/bin/stack/
    local -r buildDir=${scriptDir}/build/
    pushd ${scriptDir} > /dev/null

    echo "Running ${scriptName} in ${scriptDir}"

    ./${scriptName}

    pushd ${buildDir} > /dev/null

    local -r fileName="$(ls -1 *.tar.gz)"
    # Add the version into the filename
    local -r newFileName="${fileName/\.tar\.gz/_${BUILD_VERSION}.tar.gz}"

    echo -e "Renaming file ${GREEN}${fileName}${NC} to ${GREEN}${newFileName}${NC}"
    mv "${fileName}" "${newFileName}"  

    # Now spin up the stack to make sure it all works
    test_stack "${newFileName}"

    popd > /dev/null
    popd > /dev/null
}

test_stack() {
    local -r stack_archive_file=$1

    if [ ! -f "${stack_archive_file}" ]; then
        echo -e "${RED}Can't find file ${BLUE}${stack_archive_file}${NC}"
        exit 1
    fi

    # Although the stack was already exploded when it was built, we want to
    # make sure the tar.gz has everything in it.
    mkdir exploded_stack
    pushd exploded_stack > /dev/null

    echo -e "${GREEN}Exploding stack archive ${BLUE}${stack_archive_file}${NC}"
    tar -xvf "../${stack_archive_file}"

    echo -e "${GREEN}Installing ${BLUE}jq${GREEN} for the health check script${NC}"
    sudo apt-get install -y jq

    echo -e "${GREEN}Starting stack${NC}"
    # If the stack is unhealthy then start should exit with a non-zero code.
    ./start.sh

    # Just in case, run the health script
    ./health.sh

    ./stop.sh

    popd
}

main() {
    #Dump all the travis env vars to the console for debugging, aligned with
    # the ones above
    echo -e "TRAVIS_BUILD_NUMBER:       [${GREEN}${TRAVIS_BUILD_NUMBER}${NC}]"
    echo -e "TRAVIS_COMMIT:             [${GREEN}${TRAVIS_COMMIT}${NC}]"
    echo -e "TRAVIS_BRANCH:             [${GREEN}${TRAVIS_BRANCH}${NC}]"
    echo -e "TRAVIS_TAG:                [${GREEN}${TRAVIS_TAG}${NC}]"
    echo -e "TRAVIS_PULL_REQUEST:       [${GREEN}${TRAVIS_PULL_REQUEST}${NC}]"
    echo -e "TRAVIS_EVENT_TYPE:         [${GREEN}${TRAVIS_EVENT_TYPE}${NC}]"

    #establish what version we are building
    if [ -n "$TRAVIS_TAG" ] && [[ "$TRAVIS_TAG" =~ ${RELEASE_VERSION_REGEX} ]] ; then

        #Tagged commit so use that as our build version, e.g. v6.0.0
        BUILD_VERSION="$(echo "${TRAVIS_TAG}" | grep -oP "${VERSION_PART_REGEX}")"

        echo -e "BUILD_VERSION:             [${GREEN}${BUILD_VERSION}${NC}]"

        if [[ ${TRAVIS_TAG} =~ ${TAG_PREFIX_STROOM_NGINX} ]]; then
            #This is a stroom-nginx release, so do a docker build/push
            echo -e "${GREEN}Performing a stroom-nginx release to dockerhub${NC}"

            derive_docker_tags
            
            #build and release the image to dockerhub
            release_to_docker_hub "${DOCKER_REPO_STROOM_NGINX}" "${DOCKER_CONTEXT_ROOT_STROOM_NGINX}" ${allDockerTags}

        elif [[ ${TRAVIS_TAG} =~ ${TAG_PREFIX_STROOM_STROOM_CORE} ]]; then
            #This is a stroom_core stack release, so create the stack so travis deploy/releases can pick it up
            echo -e "${GREEN}Performing a stroom_core stack release to github${NC}"

            do_stack_build buildCore

        elif [[ ${TRAVIS_TAG} =~ ${TAG_PREFIX_STROOM_STROOM_CORE} ]]; then
            #This is a stroom_core stack release, so create the stack so travis deploy/releases can pick it up
            echo -e "${GREEN}Performing a stroom_full stack release to github${NC}"

            do_stack_build buildFull
        fi
    else
        BUILD_VERSION="SNAPSHOT"

        #No tag so finish
        echo -e "Not a tagged build so just build the stack and test it"

        # TODO need to also do the full stack at some point.
        do_stack_build buildCore
    fi
}

#Start of script
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main "$@"

exit 0
