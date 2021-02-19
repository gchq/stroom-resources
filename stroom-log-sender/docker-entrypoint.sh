#!/bin/bash
set -e

if [ "$(id -u)" = '0' ]; then

  container_env_file=/stroom-log-sender/container.env
  # This is the file in the bind mounted volume with the env vars in it
  crontab_file=/stroom-log-sender/config/crontab.txt
  # This is the transient one with the env vars replaced
  crontab_substituted_file=/stroom-log-sender/crontab_subst.txt

  if [ -f "${crontab_file}" ]; then

    # Cron will not see any of the env vars passed into the container
    # so we need to grab them from the environment and put them in a file
    # so it can be sourced in the cron job.
    # Convert the 'declare -x' => '' as declare is a bash builtin which
    # is not available when running in cron as that uses /bin/ash.
    # Thus our docker env vars will be available as shell variables if this
    # file is sourced.
    # Note docker seems to include the line 'declare -x affinity:container' on
    # some environments so need to ignore that.
    # Ignore some common env vars we don't care about
    echo "Writing env vars to ${container_env_file}"
    declare -p \
      | grep -E "^declare -x [A-Z_]+=" \
      | grep -Ev " (TERM|SHLVL|PWD|PATH|OLDPWD|HOSTNAME|HOME)(=|$)" \
      | sed 's/declare -x //g' \
      > "${container_env_file}"

    echo
    echo "Contents of ${container_env_file}:"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat "${container_env_file}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo

    # Source the env file so we have access to all the env vars
    source "${container_env_file}"

    # Now substitute all the values in the config
    echo "Substituting env vars in ${crontab_file} and" \
      "writing to ${crontab_substituted_file}"
    envsubst < "${crontab_file}" > "${crontab_substituted_file}"

    echo "(Re-)setting crontab to:"
    echo
    echo "Contents of ${crontab_substituted_file}:"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat "${crontab_substituted_file}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo
    # If we assign the crontab to the 'sender' user (crontab -u ...) it won't work, 
    # as sender dosn't have perms on /dev/stdout
    # Instead, consider using supercronic - https://github.com/aptible/supercronic/ so that
    # we can run as non-root
    /usr/bin/crontab "${crontab_substituted_file}"

    # start crond as root
    echo "Starting crond in the foreground"
    exec /usr/sbin/crond -f -l 8
  else
    echo "Error: source crontab file ${crontab_file} not found."
    echo "Quitting"
    exit 1
  fi
fi

#echo "End of entrypoint"
