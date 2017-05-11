#!/bin/bash

#Updates the IP addresses in the stroom.conf file based on running docker containers
#Assume you are using IPs rather than localhost

configFile=~/.stroom/stroom.conf

updateIp() {
    if [ $# -ne 2 ]; then
        echo "wrong args, got $@, expecting updateIp containerName dbName"
    fi
    containerName=$1
    dbName=$2

    if [ "$(docker ps -q -f name=$containerName -f status=running)" ]; then
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containerName)
        echo "Container $containerName is running on IP $ip, updating config file $configFile"
        if [ -f ~/.stroom/stroom.conf ]; then
            sed -i "s#mysql://.*/$dbName#mysql://$ip/$dbName#" $configFile
        fi
    fi

}

if [ -f $configFile ]; then

    backupFile=${configFile}.bak
    cp $configFile $backupFile

    updateIp stroom-db stroom
    updateIp stroom-stats-db statistics

    echo "File changes:"
    echo "--------------------------------------------------------------------------------"
    diff $configFile $backupFile
    echo "--------------------------------------------------------------------------------"

    rm $backupFile

else
    echo "Config file $configFile doesn't exist"
    exit 1
fi

