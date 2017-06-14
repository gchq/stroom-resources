#!/usr/bin/env bash
docker stack rm ss

# Creates config files from template - adding in the correct IP address

ip=`ip route get 1 | awk '{print $NF;exit}'`
deployRoot="../deploy"

echo "Creating nginx/nginx.conf using $ip"
sed -e 's/<SWARM_IP>/'$ip'/g' $deployRoot/template/nginx.conf > $deployRoot/nginx/nginx.conf
sed -i 's/<STROOM_URL>/'$ip'/g' $deployRoot/nginx/nginx.conf

echo "Creating swarm.yml using $ip"
sed -e 's/<STATS_DB_IP>/'$ip'/g' $deployRoot/template/swarm.yml > $deployRoot/swarm.yml
sed -i 's/<STATS_ZK_IP>/'$ip'/g' $deployRoot/swarm.yml
sed -i 's/<KAFKA_IP>/'$ip'/g' $deployRoot/swarm.yml
sed -i 's/<HBASE_ZK_IP>/'$ip'/g' $deployRoot/swarm.yml
sed -i 's/<USER_DB_IP>/'$ip'/g' $deployRoot/swarm.yml


docker-compose -f $deployRoot/nginx.yml up -d --build
docker stack deploy --compose-file $deployRoot/swarm.yml ss