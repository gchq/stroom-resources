#!/bin/sh

if [ "$#" -ne 1 ] || ! [ -f "$1" ]; then
  echo "Usage: $0 dockerComposeYmlFile" >&2
  exit 1
fi

ymlFile=$1
projectName=`basename $ymlFile | sed 's/\.yml$//'`

echo "Bouncing project $projectName with using $ymlFile"

docker-compose -f $ymlFile down && docker-compose -f $ymlFile -p $projectName up --build
