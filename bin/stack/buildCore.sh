#!/usr/bin/env bash
#
# Builds a core Stroom stack using the default configuration from the yaml.

set -e

readonly STACK_NAME="stroom_core"
readonly SERVICES="stroom stroomAllDbs stroomAuthService stroomAuthUi zookeeper nginx"

./build.sh $STACK_NAME $SERVICES
