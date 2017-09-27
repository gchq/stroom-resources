#!/bin/bash
LOCAL_HOST_NAMES="kafka hbase"

if [ "$#" -eq 0 ] || ! [ -f "$1" ]; then
  echo "Usage: $0 dockerComposeYmlFile optionalStroomDockerTag" >&2
  echo "E.g: $0 compose/everything.yml" >&2
  echo "E.g: $0 compose/everything.yml --build" >&2
  echo "E.g: $0 compose/kafka-stroom_CUSTOM_TAG-stroomDb-stroomStatsDb-zk.yml master-20170921-DAILY" >&2
  echo "E.g: $0 compose/kafka-stroom_CUSTOM_TAG-stroomDb-stroomStatsDb-zk.yml master-20170921-DAILY --build" >&2
  echo 
  echo "Possible compose files:" >&2
  ls -1 ./compose/*.yml
  exit 1
fi

ymlFile=$1
if [[ "$2" =~ ^-.*$ ]]; then
    #args from 2 onwards are extra docker args
    extraDockerArgs="${*:2}"
else
    customStroomTag=$2
    echo "Using docker tag $customStroomTag for stroom"
    export STROOM_TAG="$customStroomTag"
    #args from 3 onwards are extra docker args
    extraDockerArgs="${*:3}"
fi

projectName=`basename $ymlFile | sed 's/\.yml$//'`

isHostMissing=""

#Some of the docker containers required entires in your local hosts file to
#work correctly. This code checks they are all there
for host in $LOCAL_HOST_NAMES; do
    if [ $(cat /etc/hosts | grep -e "127\.0\.0\.1\s*$host" | wc -l) -eq 0 ]; then 
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


#Ensure we have the latest image of stroom from dockerhub
#Needed for floating tags like *-SNAPSHOT or v6
if [ $(grep -l "stroom:" $ymlFile | wc -l) -eq 1 ]; then
    echo "Compose file contains Stroom, checking for any updates to the stroom image on dockerhub"
    docker-compose -f $ymlFile -p $projectName pull stroom
fi

echo 
echo "Bouncing project $projectName with using $ymlFile with additional arguments for 'docker-compose up' [${extraDockerArgs}]"
echo "This will restart any existing containers (preserving their state), or create any containers that do not exist."
echo "If you want to rebuild images from your own dockerfiles pass the '--build' argument"
echo 

#pass any additional arguments after the yml filename direct to docker-compose
docker-compose -f $ymlFile -p $projectName stop && docker-compose -f $ymlFile -p $projectName up $extraDockerArgs
