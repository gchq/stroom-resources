#!/usr/bin/env bash
#
# Restarts the stack

source core.env
docker-compose -f <STACK_NAME>.yml restart