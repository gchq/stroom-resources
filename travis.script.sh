#!/bin/bash

#exit script on any error
set -e

#stroom-nginx
TAG_PREFIX_STROOM_NGINX="stroom-nginx"
DOCKER_REPO_STROOM_NGINX="gchq/stroom-nginx"
DOCKER_CONTEXT_ROOT_STROOM_NGINX="stroom-nginx/."

VERSION_FIXED_TAG=""
SNAPSHOT_FLOATING_TAG=""
MAJOR_VER_FLOATING_TAG=""
MINOR_VER_FLOATING_TAG=""
VERSION_PART_REGEX='v[0-9]+\.[0-9]+.*$'
RELEASE_VERSION_REGEX="^.*-${VERSION_PART_REGEX}"
LATEST_SUFFIX="-LATEST"

#Shell Colour constants for use in 'echo -e'
#e.g.  echo -e "My message ${GREEN}with just this text in green${NC}"
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Colour 

#args: dockerRepo contextRoot tag1VersionPart tag2VersionPart ... tagNVersionPart
releaseToDockerHub() {
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

    echo -e "Building and releasing a docker image to ${GREEN}${dockerRepo}${NC} with tags: ${GREEN}${allTagArgs}${NC}"
    echo -e "dockerRepo:  [${GREEN}${dockerRepo}${NC}]"
    echo -e "contextRoot: [${GREEN}${contextRoot}${NC}]"
    echo -e "allTags:     [${GREEN}${allTagArgs}${NC}]"


    docker build ${allTagArgs} ${contextRoot}

    #The username and password are configured in the travis gui
    echo -e "Logging in to DockerHub"
    docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" >/dev/null 2>&1

    #docker build ${allTagArgs} ${contextRoot} >/dev/null 2>&1
    echo -e "Pushing to DockerHub"
    docker push ${dockerRepo} >/dev/null 2>&1
}

#Start of script
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#establish what version of stroom we are building
if [ -n "$TRAVIS_TAG" ] && [[ "$TRAVIS_BRANCH" =~ ${RELEASE_VERSION_REGEX} ]] ; then
    #Tagged commit so use that as our build version, e.g. v6.0.0
    BUILD_VERSION="$(echo "${TRAVIS_TAG}" | grep -oP "${VERSION_PART_REGEX}")"

    #Dump all the travis env vars to the console for debugging
    echo -e "TRAVIS_BUILD_NUMBER:           [${GREEN}${TRAVIS_BUILD_NUMBER}${NC}]"
    echo -e "TRAVIS_COMMIT:                 [${GREEN}${TRAVIS_COMMIT}${NC}]"
    echo -e "TRAVIS_BRANCH:                 [${GREEN}${TRAVIS_BRANCH}${NC}]"
    echo -e "TRAVIS_TAG:                    [${GREEN}${TRAVIS_TAG}${NC}]"
    echo -e "TRAVIS_PULL_REQUEST:           [${GREEN}${TRAVIS_PULL_REQUEST}${NC}]"
    echo -e "TRAVIS_EVENT_TYPE:             [${GREEN}${TRAVIS_EVENT_TYPE}${NC}]"
    echo -e "BUILD_VERSION:                 [${GREEN}${BUILD_VERSION}${NC}]"

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

    if [[ ${TRAVIS_TAG} =~ ${TAG_PREFIX_STROOM_NGINX} ]]; then
        #This is a stroom-nginx release, so do a docker build/push
        DOCKER_REPO=""
        DOCKER_CONTEXT_ROOT=""
        
        #build and release the image to dockerhub
        releaseToDockerHub "${DOCKER_REPO_STROOM_NGINX}" "${DOCKER_CONTEXT_ROOT_STROOM_NGINX}" ${allDockerTags}
    fi
else
    #No tag so finish
    echo -e "Not a tagged build so doing nothing and quitting"
    exit 0
fi

exit 0
