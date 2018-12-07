#!/usr/bin/env bash 
#
# Shows the docker status for the fake-smtp container 

docker ps --filter name=fake-smtp --format "{{.Image}}\t{{.Names}}\t{{.Status}}"

