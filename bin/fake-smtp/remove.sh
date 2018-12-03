#!/bin/bash
#
# Stops the fake smtp server, removes the container and image, 
# and deletes the contents of the mail dir

# Get the dir that this script lives in, no matter where it is called from
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker stop fake-smtp
docker rm fake-smtp
docker rmi munkyboy/fakesmtp:latest
rm "${SCRIPT_DIR}/volume/*"
