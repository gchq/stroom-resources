#!/bin/bash
set -e


# These should be set in the dockerfile, but just in case
USER_ID="${USER_ID:-1000}"
GROUP_ID="${GROUP_ID:-0}"
# This is the file in the bind mounted volume with the env vars in it
CRONTAB_FILE=/stroom-log-sender/config/crontab.txt


if [ ! -f "${CRONTAB_FILE}" ]; then
  echo "Error: source crontab file ${CRONTAB_FILE} not found."
  echo "Quitting"
  exit 1
fi

echo "Dumping environment variables"
echo "----------------------------------------------------------"
env \
  | uniq \
  | sort
echo "----------------------------------------------------------"


# In case anyone tries to run the container as root drop down
if [ "$(id -u)" = '0' ]; then
    #su-exec is the alpine equivalent of gosu
    #runs all args as user USER_ID:GROUP_ID, rather than as root
    echo "Running supercronic via su-exec as $USER_ID:$GROUP_ID"
    exec su-exec "$USER_ID:$GROUP_ID" "$@"
else
  # Already non-root so just crack on and run the cmd as is
  echo "Running supercronic"
  exec "$@"
fi
