#!/bin/bash
LOCAL_HOST_NAMES="kafka hbase"

if [ "$#" -eq 0 ] || ! [ -f "$1" ]; then
  echo "Usage: $0 dockerComposeYmlFile optionalStroomDockerTag" >&2
  echo "E.g: $0 compose/everything.yml" >&2
  echo "E.g: $0 compose/kafka-stroom_CUSTOM_TAG-stroomDb-stroomStatsDb-zk.yml master-20170921-DAILY" >&2
  echo 
  echo "Possible compose files:" >&2
  ls -1 ./compose/*.yml
  exit 1
fi

ymlFile=$1
customStroomTag=$2

projectName=`basename $ymlFile | sed 's/\.yml$//'`

isHostMissing=""

#Some of the docker containers required entires in your local hosts file to
#work correctly. This code checks they are all there
for host in $LOCAL_HOST_NAMES; do
    if [ $(cat /etc/hosts | grep "127.0.0.1 $host" | wc -l) -eq 0 ]; then 
        echo "ERROR - /etc/hosts is missing an entry for \"127.0.0.1 $host\""
        isHostMissing=true
        echo "Add the following line to /etc/hosts:"
        echo "127.0.0.1 $host"
        echo
    fi
done

if [ $isHostMissing ]; then
    echo "Quting!"
    exit 1
fi

if [ $customStroomTag ]; then
    echo "Using docker tag $customStroomTag for stroom"
    export STROOM_TAG="$customStroomTag"
    #args from 3 onwards are extra docker args
    extraDockerArgs="${*:3}"
else
    #args from 2 onwards are extra docker args
    extraDockerArgs="${*:2}"
fi

#Ensure we have the latest image of stroom from dockerhub
#Needed for floating tags like *-SNAPSHOT or v6
if [ $(grep -l "stroom:" $ymlFile | wc -l) -eq 1 ]; then
    echo "Checking for latest stroom image"
    docker-compose -f $ymlFile pull stroom
fi

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

#pass any additional arguments after the yml filename direct to docker-compose
docker-compose -f $ymlFile down && docker-compose -f $ymlFile -p $projectName up --build $extraDockerArgs
