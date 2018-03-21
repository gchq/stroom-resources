#!/usr/bin/env bash
#
# Builds a core Stroom stack using the default configuration from the yaml.

readonly STACK_NAME="stroom_core"
readonly SERVICES="stroom stroomDb stroomAuthService stroomAuthUi stroomAuthDb stroomStatsDb zookeeper nginx"

./create_stack_yaml.sh $STACK_NAME $SERVICES
./create_stack_env.sh $STACK_NAME
./create_stack_scripts.sh $STACK_NAME
./create_stack_assets.sh $STACK_NAME