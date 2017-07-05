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

echo "Bouncing project $projectName with using $ymlFile"

# Creates config files from template - adding in the correct IP address
ip=`ip route get 1 | awk '{print $NF;exit}'`
deployRoot="../deploy"
echo "Creating nginx/nginx.conf using $ip"
sed -e 's/<SWARM_IP>/'$ip'/g' $deployRoot/template/nginx.conf > $deployRoot/nginx/nginx.conf
sed -i 's/<STROOM_URL>/'$ip'/g' $deployRoot/nginx/nginx.conf
sed -i 's/<AUTH_UI_URL>/'$ip'/g' $deployRoot/nginx/nginx.conf

#pass any additional arguments after the yml filename direct to docker-compose
docker-compose -f $ymlFile down && docker-compose -f $ymlFile -p $projectName up --build ${*:2}
