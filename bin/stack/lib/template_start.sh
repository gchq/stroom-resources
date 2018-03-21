#!/usr/bin/env bash
#
# Starts the stack, using the configuration defined in the .env file.

source lib/network_utils.sh
HOST_IP=$(determine_host_address)
source config/core.env

docker-compose -f config/<STACK_NAME>.yml up -d