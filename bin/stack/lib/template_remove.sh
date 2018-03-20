#!/usr/bin/env bash
#
# Removes the stack from the host. All containers are stopped and removed. So are their volumes!

docker-compose -f <STACK_NAME>.yml down -v