#!/bin/sh

imageCount=$(docker images |  grep "gchq/stroom" | awk '{print $1 ":" $2}' | wc -l)

if [ $imageCount -eq 0 ]; then
    echo "No stroom images to delete"
else
    echo "Deleting the following stroom docker images:"
    docker images |  grep "gchq/stroom" | awk '{print $1 ":" $2}'
    echo ""

    docker images |  grep "gchq/stroom" | awk '{print $1 ":" $2}' | xargs docker rmi
fi

