#!/usr/bin/env bash

echo "JVMFLAGS [$JVMFLAGS]"

echo "Running zkServer.sh with command [$@]"

exec /opt/zookeeper/bin/zkServer.sh "$@"

