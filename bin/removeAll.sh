#!/bin/bash

CONTAINERS=$(docker ps -a -q)
if [ ${#CONTAINERS} -ge 1 ]; then
  echo $CONTAINERS
  docker stop $CONTAINERS
  docker rm $CONTAINERS
else
  echo "There are no existing containers"
fi
