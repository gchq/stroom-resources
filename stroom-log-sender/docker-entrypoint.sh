#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then

  crontab_file=/stroom-log-sender/config/crontab.txt
  container_env_file=/stroom-log-sender/container.env

  if [ -f "${crontab_file}" ]; then

    # Cron will not see any of the env vars passed into the container
    # so we need to grab them from the environment and put them in a file
    # so it can be sourced in the cron job.
    # Convert the 'declare -x' => '' as declare is a bash builtin which
    # is not available when running in cron as that uses /bin/ash.
    # Thus our docker env vars will be available as shell variables if this
    # file is sourced.
    echo "Writing env vars to ${container_env_file}"
    declare -p \
      | grep -E "^declare -x" \
      | grep -Ev " (TERM|SHLVL|PWD|PATH|OLDPWD|HOSTNAME|HOME)(=|$)" \
      | sed 's/declare -x //g' \
      > "${container_env_file}"

    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat "${container_env_file}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    echo "(Re-)setting crontab to:"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat "${crontab_file}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # If we assign the crontab to the 'sender' user (crontab -u ...) it won't work, 
    # as sender dosn't have perms on /dev/stdout
    # Instead, consider using supercronic - https://github.com/aptible/supercronic/ so that
    # we can run as non-root
    /usr/bin/crontab "${crontab_file}"

        # start crond as root
        echo "Starting crond in the foreground"
        exec /usr/sbin/crond -f -l 8
      else
        echo "Error: crontab file ${crontab_file} not found"
        echo "Quitting"
        exit 1
  fi
fi

#echo "End of entrypoint"
