#!/usr/bin/env bash

# Creates config files from template - adding in the correct IP address
ip=`ip route get 1 | awk '{print $NF;exit}'`
deployRoot="../deploy"

echo "Creating swarm.yml using $ip"
sed -e 's/<STATS_DB_IP>/'$ip'/g' $deployRoot/template/swarm.yml > $deployRoot/swarm.yml
sed -i 's/<STATS_ZK_IP>/'$ip'/g' $deployRoot/swarm.yml
sed -i 's/<KAFKA_IP>/'$ip'/g' $deployRoot/swarm.yml
sed -i 's/<HBASE_ZK_IP>/'$ip'/g' $deployRoot/swarm.yml
sed -i 's/<USER_DB_IP>/'$ip'/g' $deployRoot/swarm.yml

docker stack rm ss
docker stack deploy --compose-file $deployRoot/swarm.yml ss