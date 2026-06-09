#!/bin/bash
set -e

# This is the file in the bind mounted volume with the env vars in it
crontab_file=/stroom-log-sender/config/crontab.txt

if [ ! -f "${crontab_file}" ]; then
  echo "Error: source crontab file ${crontab_file} not found."
  echo "Quitting"
  exit 1
fi

echo "Dumping environment variables"
echo "----------------------------------------------------------"
env \
  | uniq \
  | sort
echo "----------------------------------------------------------"

echo "Running supercronic"
exec "$@"

#echo "End of entrypoint"
