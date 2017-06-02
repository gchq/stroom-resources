#!/bin/bash

declare -a containers=(
    "stroom"
    "stroom"
    "stroom-db"
    "stroom-stats-db"
    "kafka"
    "hbase"
    "zookeeper")

for container in "${containers[@]}"; do
    echo "Stopping and removing container $container"
    docker stop $container
    docker rm $container
done
    
