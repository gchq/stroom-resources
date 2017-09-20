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

# We need to know where we're running this from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# We need the IP to transpose into our config
ip=`ip route get 1 | awk '{print $NF;exit}'`

# This is used by the docker-compose YML files, so they can tell a browser where to go
echo "Using the following IP as the advertised host: $ip"
export STROOM_RESOURCES_ADVERTISED_HOST=$ip

# NGINX: creates config files from templates, adding in the correct IP address
deployRoot=$DIR/"../deploy"
echo "Creating nginx/nginx.conf using $ip"
sed -e 's/<SWARM_IP>/'$ip'/g' $deployRoot/template/nginx.conf > $deployRoot/nginx/nginx.conf
sed -i 's/<STROOM_URL>/'$ip'/g' $deployRoot/nginx/nginx.conf
sed -i 's/<AUTH_UI_URL>/'$ip'/g' $deployRoot/nginx/nginx.conf

# Pass any additional arguments after the yml filename direct to docker-compose
docker-compose -f $ymlFile down && docker-compose -f $ymlFile -p $projectName up --build ${*:2}
