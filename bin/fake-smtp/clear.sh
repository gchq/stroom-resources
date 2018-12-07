#!/usr/bin/env bash 
#
# Deletes all received emails

docker exec -it fake-smtp sh -c 'rm -f /var/mail/*'
