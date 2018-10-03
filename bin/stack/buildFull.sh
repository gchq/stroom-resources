#!/usr/bin/env bash
#
# Builds a full Stroom stack using the default configuration from the yaml.

set -e

readonly STACK_NAME="stroom_full"
readonly SERVICES="stroom stroomDb stroomAuthService stroomAuthUi stroomAuthDb stroomStatsDb nginx elasticsearch hbase hdfs kafka kibana stroomAnnotationsDb stroomAnnotationsService stroomAnnotationsUi stroomProxy stroomQueryElasticService stroomQueryElasticUi stroomStats zookeeper"

./build.sh $STACK_NAME $SERVICES
