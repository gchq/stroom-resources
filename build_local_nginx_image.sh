#!/bin/bash

# Check for uncommitted work
if [ "$(git status --porcelain 2>/dev/null | wc -l)" -eq 0 ]; then
    GIT_COMMIT="$(git rev-parse HEAD)"
else
    GIT_COMMIT="unspecified"
fi

docker build \
    --tag gchq/stroom-nginx:local-SNAPSHOT \
    --build-arg GIT_COMMIT="${GIT_COMMIT}" \
    ./stroom-nginx
