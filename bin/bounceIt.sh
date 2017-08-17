#!/bin/bash

if [ "$#" -eq 0 ] || ! [ -f "$1" ]; then
  echo "Usage: $0 dockerComposeYmlFile" >&2
  echo "E.g: $0 compose/everything.yml" >&2
  echo "Possible compose files:" >&2
  ls -1 ./compose/*.yml
  exit 1
fi

ymlFile=$1
projectName=`basename $ymlFile | sed 's/\.yml$//'`

#Ensure we have the latest image of stroom from dockerhub
#Needed for floating tags like *-SNAPSHOT or v6
if [ $(grep -l "stroom:" $ymlFile | wc -l) -eq 1 ]; then
    echo "Checking for latest stroom image"
    docker-compose -f $ymlFile pull stroom
fi

echo "Bouncing project $projectName with using $ymlFile"

#pass any additional arguments after the yml filename direct to docker-compose
docker-compose -f $ymlFile down && docker-compose -f $ymlFile -p $projectName up --build ${*:2}
