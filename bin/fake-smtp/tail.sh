#!/usr/bin/env bash 
#
# Tails the received emails

docker exec -it fake-smtp sh -c 'tail /var/mail/*'
