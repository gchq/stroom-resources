#!/usr/bin/env bash
#
# Builds a full Stroom stack using the default configuration from the yaml.

set -e

main() {
    local -r VERSION=$1
    local -r BUILD_STACK_NAME="stroom_full"
    local -r SERVICES="stroom stroomProxyLocal stroomAllDbs stroomAuthService stroomAuthUi stroomLogSender nginx elasticsearch hbase hdfs kafka kibana stroomAnnotationsService stroomAnnotationsUi stroomProxy stroomQueryElasticService stroomQueryElasticUi stroomStats zookeeper"

    ./build.sh ${BUILD_STACK_NAME} ${VERSION:-SNAPSHOT} ${SERVICES}
}

main "$@"
