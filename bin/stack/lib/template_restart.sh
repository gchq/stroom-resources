#!/usr/bin/env bash
#
# Restarts the stack

source lib/network_utils.sh
HOST_IP=$(determine_host_address)
source config/core.env

docker-compose -f config/<STACK_NAME>.yml restart