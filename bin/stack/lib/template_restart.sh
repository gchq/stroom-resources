#!/usr/bin/env bash
#
# Restarts the stack

source core.env
docker-compose -f config/<STACK_NAME>.yml restart