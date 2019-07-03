#!/usr/bin/env bash
#
# Builds a Stroom 'stack' with just Stroom,  using the default configuration from the yaml.

set -e

main() {
  local -r VERSION=$1
  local -r BUILD_STACK_NAME="stroom"

  local SERVICES=()

  # Define all the services that make up the stack
  # Array created like this to allow lines to commneted out
  SERVICES+=("stroom")
  SERVICES+=("stroom-log-sender")

  ./build.sh "${BUILD_STACK_NAME}" "${VERSION:-SNAPSHOT}" "${SERVICES[@]}"
}

main "$@"
