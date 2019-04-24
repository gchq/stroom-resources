#!/bin/sh

BASE_DIR="/stroom-nginx"
LOGS_DIR="${BASE_DIR}/logs"
CONFIG_DIR="${BASE_DIR}/config"
LOG_SENDER_HEADERS_FILE="${LOGS_DIR}/extra_headers.txt"

set -e

echo "Substituting variables to generate nginx.conf"

# We need to create nginx.conf from nginx.conf.template, 
# substituting NGINX_ADVERTISED_HOST from its environment variable
# As nginx.conf contains stuff like '$proxy_add_x_forwarded_for', 
# we need to give envsubst a specific list of variables
# to substitute, else it will breake the config
# shellcheck disable=SC2016
envsubst '
    ${NGINX_ADVERTISED_HOST}
    ${STROOM_HOST}
    ${STROOM_PORT}
    ${STROOM_PROXY_HOST}
    ${STROOM_PROXY_PORT}
    ${AUTH_SERVICE_HOST}
    ${AUTH_SERVICE_PORT}
    ${AUTH_UI_URL}
    ${ANNOTATIONS_UI_URL}
    ${QUERY_ELASTIC_UI_URL}
    ${NGINX_HTML_ROOT_PATH}
    ${NGINX_SSL_VERIFY_CLIENT}
    ${NGINX_SSL_CERTIFICATE}
    ${NGINX_SSL_CERTIFICATE_KEY}
    ${NGINX_SSL_CLIENT_CERTIFICATE}
    ${NGINX_CLIENT_BODY_BUFFER_SIZE}
    ' \
    < "${CONFIG_DIR}/nginx.conf.template" \
    > /etc/nginx/nginx.conf

echo "Ensuring directories"
# Ensure we have the sub-directories in our /nginx/logs/ volume
mkdir -p "${LOGS_DIR}/access"
mkdir -p "${LOGS_DIR}/app"

# shellcheck source=add_container_identity_headers.sh
. "${BASE_DIR}/add_container_identity_headers.sh" "${LOG_SENDER_HEADERS_FILE}"

crontab_file="${CONFIG_DIR}/crontab.txt"
logrotate_template_file="${CONFIG_DIR}/logrotate.conf.template"
logrotate_conf_file="${BASE_DIR}/logrotate/logrotate.conf"

if [ -f "${logrotate_template_file}" ]; then

    echo "Creating ${logrotate_conf_file} from ${logrotate_template_file}"
    cp "${logrotate_template_file}" "${logrotate_conf_file}"
    # logrotate is fussy about the ownership/permissions of the conf file
    chmod -R 400 "${logrotate_conf_file}"

else
    echo "WARN: logrotate template file ${logrotate_template_file} not found, nginx logs won't be rotated"
fi

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
    echo "Starting crond in the background"

    /usr/sbin/crond -l 8 && \
        echo "Starting CMD: [" "$@" "]" && \
        exec "$@"
else
    echo "WARN: crontab file ${crontab_file} not found, can't start cron, nginx logs won't be rotated"
    # Now run the CMD
    echo "Starting CMD: [" "$@" "]"
    exec "$@"
fi
