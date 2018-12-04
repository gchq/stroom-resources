#!/usr/bin/env bash
#
# Builds a full Stroom stack using the default configuration from the yaml.

set -e

main() {
    local -r VERSION=$1
    local -r BUILD_STACK_NAME="stroom_full"
    local -r SERVICES=( \ 
        "elasticsearch" \ 
        "hbase" \ 
        "hdfs" \ 
        "kafka" \ 
        "kibana" \ 
        "nginx" \ 
        "stroom" \ 
        "stroomAllDbs" \ 
        "stroomAnnotationsService" \ 
        "stroomAnnotationsUi" \ 
        "stroomAuthService" \ 
        "stroomAuthUi" \ 
        "stroomLogSender" \ 
        "stroomProxy" \ 
        "stroomProxyLocal" \ 
        "stroomQueryElasticService" \ 
        "stroomQueryElasticUi" \ 
        "stroomStats" \ 
        "zookeeper" \ 
        )

    ./build.sh "${BUILD_STACK_NAME}" "${VERSION:-SNAPSHOT}" "${SERVICES[@]}"
}

main "$@"
