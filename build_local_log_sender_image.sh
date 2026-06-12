#!/bin/bash

DOCKER_IMAGE_TAG="local-SNAPSHOT"
GIT_TAG="${DOCKER_IMAGE_TAG}"

# Check for uncommitted work
if [ "$(git status --porcelain 2>/dev/null | wc -l)" -eq 0 ]; then
    GIT_COMMIT="$(git rev-parse HEAD)"
else
    GIT_COMMIT="unspecified"
fi

docker build \
    --tag gchq/stroom-log-sender:local-SNAPSHOT \
    --build-arg GIT_COMMIT="${GIT_COMMIT}" \
    --build-arg GIT_TAG="${GIT_TAG}" \
    ./stroom-log-sender
