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

#Stop script on first error
set -e

DOCKER_REPO=gchq/stroom-zookeeper

if [ $# -ne 1 ]; then
    echo "Must supply the version as the first argument, e.g. $0 v1.0.0_zk-v3.4.5"
    exit 1
fi

# This script is all you need to build an image of stroom-stats.
ver="$1"

docker build --tag ${DOCKER_REPO}:${ver} ./zookeeper/

# This assumes you have authenticated with docker using 'docker login', else it will fail
docker push ${DOCKER_REPO}:${ver}
