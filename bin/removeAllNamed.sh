#!/bin/bash

declare -a containers=(
    "stroom-5"
    "stroom"
    "stroom-db"
    "stroom-stats-db"
    "kafka"
    "hbase"
    "solr"
    "zookeeper")

for container in "${containers[@]}"; do
    echo "Stopping and removing container $container"
    docker stop $container
    docker rm $container
done
    
