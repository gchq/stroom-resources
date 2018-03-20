#!/usr/bin/env bash
#
# Starts the stack, using the configuration defined in the .env file.

source core.env
docker-compose -f <STACK_NAME>.yml up -d