#!/bin/bash

CONTAINERS=$(docker ps -a -q)
if [ ${#CONTAINERS} -ge 1 ]; then
  echo $CONTAINERS
  docker stop $CONTAINERS
  docker rm $CONTAINERS
else
  echo "There are no existing containers"
fi

# remove exited containers:
docker ps --filter status=dead --filter status=exited -aq | xargs docker rm -v

# remove unused images:
docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs docker rmi

# remove unused volumes:
docker volume ls -qf dangling=true | xargs docker volume rm

# Remove the externalised database volumes
rm -rf ~/.stroom/db_data/
