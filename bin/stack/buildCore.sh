#!/usr/bin/env bash
#
# Builds a core stack using the default version from the yaml.

readonly STACK_NAME="core"

./create_stack_yaml.sh $STACK_NAME stroom stroomDb stroomAuthService stroomAuthUi stroomAuthDb stroomStatsDb zookeeper ctop nginx
./create_stack_env.sh $STACK_NAME
./create_stack_scripts.sh $STACK_NAME