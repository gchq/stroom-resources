#!/bin/sh
set -e

if [ "$(id -u)" = '0' ]; then

    crontab_file=/stroom-log-sender/config/crontab.txt

    if [ -f "${crontab_file}" ]; then
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
