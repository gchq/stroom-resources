#!/bin/sh

# remove exited containers:
docker ps --filter status=dead --filter status=exited -aq | xargs -r docker rm -v
    
# remove unused images:
docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs -r docker rmi

# remove unused volumes:
docker volume ls -qf dangling=true | xargs -r docker volume rm

# Remove the externalised database volumes
while true; do
    read -p "Do you wish to clean up the local dev database volumes (will prompt for root pw)? " yn
    case $yn in
        [Yy]* ) sudo rm -rf ~/.stroom/db_data/; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done