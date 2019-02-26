#!/usr/bin/env bash
#
# Builds a core Stroom stack using the default configuration from the yaml.

set -e

main() {
    local -r VERSION=$1
    local -r BUILD_STACK_NAME="stroom_core"

    local SERVICES=()

    # Define all the services that make up the stack
    # Array created like this to allow lines to commneted out
    SERVICES+=("nginx")
    SERVICES+=("stroom")
    SERVICES+=("stroom-all-dbs")
    SERVICES+=("stroom-auth-service")
    SERVICES+=("stroom-auth-ui")
    SERVICES+=("stroom-log-sender")
    SERVICES+=("stroom-proxy-local")
    SERVICES+=("stroom-proxy-remote")

    ./build.sh "${BUILD_STACK_NAME}" "${VERSION:-SNAPSHOT}" "${SERVICES[@]}"
}

main "$@"
