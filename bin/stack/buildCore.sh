#!/usr/bin/env bash
#
# Builds a core stack using the default version from the yaml.

./create_stack_yaml.sh core stroom stroomDb stroomAuthService stroomAuthUi stroomAuthDb stroomStatsDb zookeeper ctop nginx
./create_stack_env.sh core
./create_stack_scripts.sh core