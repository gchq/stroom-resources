#!/usr/bin/env bash

#**********************************************************************
# Copyright 2016 Crown Copyright
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#**********************************************************************

#**********************************************************************
# Script to build the stroom-nginx docker image and release it to 
# DockerHub
#**********************************************************************

#Shell Colour constants for use in 'echo -e'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
LGREY='\e[37m'
DGREY='\e[90m'
NC='\033[0m' # No Color

#Stop script on first error
set -e

DOCKER_REPO=gchq/stroom-nginx

showUsage() {
    echo -e "Usage: ${BLUE}$0 [-l] dockerTag"
    echo -e "OPTIONs:"
    echo -e "  ${GREEN}-l${NC} - Local build only, won't push to DockerHub"
    echo -e "e.g.: ${BLUE}$0 -l v1.2.3${NC}"
    echo -e "e.g.: ${BLUE}$0 v1.2.3${NC}"
    echo
}

localBuild=false

optspec=":l"
while getopts "$optspec" optchar; do
    #echo "Parsing $optchar"
    case "${optchar}" in
        l)
            localBuild=true
            ;;
        *)
            echo -e "${RED}ERROR${NC} Unknown argument: '-${OPTARG}'" >&2
            echo
            showUsage
            exit 1
            ;;
    esac
done

shift $((OPTIND -1))

if [ $# -ne 1 ]; then
    echo "Must supply the dockerTag"
    showUsage
    exit 1
fi

# This script is all you need to build an image of stroom-stats.
ver="$1"

echo
echo -e "${GREEN}Building ${BLUE}${DOCKER_REPO}:${ver}${NC}"
echo

docker build --tag ${DOCKER_REPO}:${ver} .

if ! ${localBuild}; then
    echo
    echo -e "${GREEN}Pushing to DockerHub (will fail if you haven't run '${BLUE}docker login${GREEN}'${NC}"
    echo
    # This assumes you have authenticated with docker using 'docker login', else it will fail
    docker push ${DOCKER_REPO}:${ver}
fi
