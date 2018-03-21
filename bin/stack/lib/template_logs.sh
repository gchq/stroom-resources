#!/usr/bin/env bash
#
# Shows the stacks logs

docker-compose -f config/<STACK_NAME>.yml logs -f