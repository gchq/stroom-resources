#!/bin/bash

function cloneOrUpdate {
    if [[ -d $1 ]]; then
        # Update the repo
        echo -e "Checking repo \e[96m$1\e[0m for updates"
        cd $1
        git pull
        cd ..
    else
        # Clone the repo
        echo -e "Cloning \e[96m$1\e[0m"
        git clone git@github.com:gchq/$1.git
    fi
}

function cloneOrUpdateAllRepos {
    # We need to be cloning siblings of stroom-resources, and this script resides in stroom-resources/bin
    cd ../..

    cloneOrUpdate stroom
    cloneOrUpdate stroom-stats
    cloneOrUpdate stroom-auth
    cloneOrUpdate stroom-proxy
    cloneOrUpdate stroom-query
    cloneOrUpdate stroom-docs
    cloneOrUpdate stroom-visualisations-dev
    cloneOrUpdate stroom-expression
    cloneOrUpdate stroom-agent
    cloneOrUpdate stroom-clients
    cloneOrUpdate stroom-content

    cloneOrUpdate event-logging
    cloneOrUpdate event-logging-schema

    cloneOrUpdate urlDependencies-plugin

    # We don't necessarily need the shaded repos because we pull these dependencies
    # down using urlDependencies-plugin
    cloneOrUpdate hadoop-common-shaded
    cloneOrUpdate hadoop-hdfs-shaded
    cloneOrUpdate hbase-common-shaded

    # Are these defunct?
    #cloneOrUpdate stroom-timeline
    #cloneOrUpdate stroom-timeline-loaded
    #cloneOrUpdate stroom-shaded-dependencies
}

while true; do
    echo "This will clone or pull all Stroom related repos as siblings of stroom-resources. "
    read -p "Are you sure you want to do this? [y/n]" yn
    case $yn in
        [Yy]* ) cloneOrUpdateAllRepos; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
