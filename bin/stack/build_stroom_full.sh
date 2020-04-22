#!/usr/bin/env bash
#
# Builds a full Stroom stack using the default configuration from the yaml.

set -e

main() {
  local -r VERSION=$1
  local -r BUILD_STACK_NAME="stroom_full"
  local SERVICES=()

  # Define all the services that make up the stack
  # Array created like this to allow lines to commneted out
  #SERVICES+=("elasticsearch")
  SERVICES+=("hbase")
  SERVICES+=("hdfs")
  SERVICES+=("kafka")
  #SERVICES+=("kibana")
  SERVICES+=("nginx")
  SERVICES+=("stroom")
  SERVICES+=("stroom-all-dbs")
  SERVICES+=("stroom-log-sender")
  SERVICES+=("stroom-proxy-local")
  SERVICES+=("stroom-proxy-remote")
  #SERVICES+=("stroom-query-elastic-service")
  #SERVICES+=("stroom-query-elastic-ui")
  SERVICES+=("stroom-stats")
  SERVICES+=("zookeeper")

  ./build.sh "${BUILD_STACK_NAME}" "${VERSION:-SNAPSHOT}" "${SERVICES[@]}"
}

main "$@"
