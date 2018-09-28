#!/bin/sh

# 'xargs -r' doesn't work on MacOS, see 
# https://stackoverflow.com/questions/17402345/ignore-empty-results-for-xargs-in-mac-os-x
# Suggest you use GNU xargs from 'brew install findutils'

echo "Recreating stroom-db and stroom-stats-db"

# Doesn't touch auth-db to keep any password changes intact

docker stop stroom-db
docker stop stroom-stats-db

docker rm stroom-db
docker rm stroom-stats-db

# Remove the externalised database volumes
while true; do
    read -p "Do you wish to clean up the local dev database volumes (will prompt for root pw)? " yn
    case $yn in
        [Yy]* ) 
            sudo rm -rf ~/.stroom/db_data/stroom-db
            sudo rm -rf ~/.stroom/db_data/stroom-stats-db
            break;;
        [Nn]* ) 
            exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

./bounceIt.sh create -y -i stroom-db stroom-stats-db
./bounceIt.sh start -y -i stroom-db stroom-stats-db
