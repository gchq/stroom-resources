#!/usr/bin/env bash
#
# Shows the status of the stack.

docker \
  ps \
  --all \
  --filter "label=stack_name=<STACK_NAME>" \
  --format  "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.ID}}"
