#!/usr/bin/env bash

# Creates config files from template - adding in the correct IP address
ip=`ip route get 1 | awk '{print $NF;exit}'`
deployRoot="../deploy"

echo "Creating nginx/nginx.conf using $ip"
sed -e 's/<SWARM_IP>/'$ip'/g' $deployRoot/template/nginx.conf > $deployRoot/nginx/nginx.conf
sed -i 's/<STROOM_URL>/'$ip'/g' $deployRoot/nginx/nginx.conf

docker-compose -f $deployRoot/nginx.yml down
docker-compose -f $deployRoot/nginx.yml up -d --build


