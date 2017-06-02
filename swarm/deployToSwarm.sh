#!/bin/sh

docker-compose -f nginx.yml up -d
docker stack deploy --compose-file swarm.yml ss