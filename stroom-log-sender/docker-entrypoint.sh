#!/bin/sh
set -e

# Re-set permission to the `sender` user if current user is root
# This avoids permission denied if the data volume is mounted by root
if [ "$(id -u)" = '0' ]; then
  # dump the environment variables
  echo "Dumping environment variables"
  echo "----------------------------------------------------------"
  env \
    | uniq \
    | sort
  echo "----------------------------------------------------------"

  #chown sender:sender /stroom-log-sender/log-volumes

  # run the COMMAND as user 'sender'
  exec su-exec sender "$@"
fi
