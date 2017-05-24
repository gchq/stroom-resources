#!/bin/sh

if [ "$#" -ne 1 ] || ! [ -f "$1" ]; then
  echo "Usage: $0 dockerComposeYmlFile" >&2
  exit 1
fi

ymlFile=$1

# Swarm does not support 'extends' so we need to hack around our YML files
## `docker-compose`` config expects a file named `docker-compose.yml`
cp $ymlFile docker-compose.yml
## `config`` validates and prints the compose file, and we can pipe it to get something we can use with `docker stack deploy`
docker-compose config > swarm.yml
rm docker-compose.yml

# `docker stack deploy` requires a docker-compose file in version 3. We can't change our yml to version

# Deploy
docker stack deploy --compose-file swarm.yml stroom_stack