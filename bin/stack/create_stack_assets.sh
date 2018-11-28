#!/usr/bin/env bash
#
# Copies the necessary assets into the build

set -e

source lib/shell_utils.sh

download_file() {
    local -r dest_dir=$1
    local -r url_base=$2
    local -r filename=$3

    echo -e "  Downloading ${BLUE}${url_base}/${filename}${NC} to ${BLUE}${dest_dir}${NC}"
    wget --quiet --directory-prefix="${dest_dir}" "${url_base}/${filename}"
    if [[ "${filename}" =~ .*\.sh$ ]]; then
        chmod u+x "${dest_dir}/${filename}"
    fi
}

main() {
    setup_echo_colours

    [ "$#" -ge 2 ] || die "${RED}Error${NC}: Invalid arguments, usage: ${BLUE}build.sh stackName serviceX serviceY etc.${NC}"

    local -r services=( "${@:2}" )

    echo -e "${GREEN}Copying assets${NC}"

    local -r BUILD_STACK_NAME=$1
    local -r VERSION=$2
    local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
    local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}"
    local -r VOLUMES_DIRECTORY="${BUILD_DIRECTORY}/volumes"

    local -r SRC_CERTS_DIRECTORY="../../dev-resources/certs"
    local -r SRC_NGINX_CONF_DIRECTORY="../../stroom-nginx/template"
    local -r SRC_VOLUMES_DIRECTORY="../../dev-resources/compose/volumes"
    local -r SRC_ELASTIC_CONF_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/elasticsearch/conf"
    local -r SRC_KIBANA_CONF_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/kibana/conf"
    local -r SRC_STROOM_LOG_SENDER_CONF_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/stroom-log-sender/conf"
    local -r SRC_AUTH_UI_CONF_DIRECTORY="../../stroom-microservice-ui/template"
    local -r SEND_TO_STROOM_VERSION="send-to-stroom-v1.3"
    local -r SEND_TO_STROOM_URL_BASE="https://raw.githubusercontent.com/gchq/stroom-clients/${SEND_TO_STROOM_VERSION}/bash"

    local -r DEST_PROXY_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-proxy/certs"
    mkdir -p "${DEST_PROXY_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.jks" "${DEST_PROXY_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/server/server.jks" "${DEST_PROXY_CERTS_DIRECTORY}"

    local -r DEST_AUTH_UI_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/auth-ui/certs"
    mkdir -p "${DEST_AUTH_UI_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" "${DEST_AUTH_UI_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/server/server.pem.crt" "${DEST_AUTH_UI_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/server/server.unencrypted.key" "${DEST_AUTH_UI_CERTS_DIRECTORY}"

    local -r DEST_AUTH_UI_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/auth-ui/conf"
    mkdir -p "${DEST_AUTH_UI_CONF_DIRECTORY}"
    cp "${SRC_AUTH_UI_CONF_DIRECTORY}/nginx.conf.template" "${DEST_AUTH_UI_CONF_DIRECTORY}"

    local -r DEST_NGINX_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/certs"
    mkdir -p "$DEST_NGINX_CERTS_DIRECTORY"
    cp "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" "${DEST_NGINX_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/server/server.pem.crt" "${DEST_NGINX_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/server/server.unencrypted.key" "${DEST_NGINX_CERTS_DIRECTORY}"

    local -r DEST_NGINX_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/conf"
    mkdir -p "${DEST_NGINX_CONF_DIRECTORY}"
    cp "${SRC_NGINX_CONF_DIRECTORY}/nginx.conf.template" "${DEST_NGINX_CONF_DIRECTORY}"

    # Set up the client certs needed for the send_data script
    local -r DEST_CLIENT_CERTS_DIRECTORY="${WORKING_DIRECTORY}/certs"
    mkdir -p "${DEST_CLIENT_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" "${DEST_CLIENT_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/client/client.pem.crt" "${DEST_CLIENT_CERTS_DIRECTORY}"
    cp "${SRC_CERTS_DIRECTORY}/client/client.unencrypted.key" "${DEST_CLIENT_CERTS_DIRECTORY}"

    # Get the send_to_stroom* scripts we need for the send_data script
    local -r DEST_LIB_DIR="${WORKING_DIRECTORY}/lib"
    download_file "${DEST_LIB_DIR}" "${SEND_TO_STROOM_URL_BASE}" "send_to_stroom.sh"
    download_file "${DEST_LIB_DIR}" "${SEND_TO_STROOM_URL_BASE}" "send_to_stroom_args.sh"

    # If elasticsearch is in the list of services add its volume
    if [[ " ${services[@]} " =~ \\selasticsearch\\s ]]; then
        local -r DEST_ELASTIC_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/elasticsearch/conf"
        mkdir -p "${DEST_ELASTIC_CONF_DIRECTORY}"
        cp "${SRC_ELASTIC_CONF_DIRECTORY}/*" "${DEST_ELASTIC_CONF_DIRECTORY}"
    fi

    # If stroom-log-sender is in the list of services add its volume
    if [[ " ${services[@]} " =~ \\sstroomLogSender\\s ]]; then

        local -r DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-log-sender/certs"
        mkdir -p "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"
        cp "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"
        cp "${SRC_CERTS_DIRECTORY}/client/client.pem.crt" "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"
        cp "${SRC_CERTS_DIRECTORY}/client/client.unencrypted.key" "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"

        local -r DEST_STROOM_LOG_SENDER_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-log-sender/conf"
        mkdir -p "${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}"
        cp "${SRC_STROOM_LOG_SENDER_CONF_DIRECTORY}/*" "${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}"
    fi

    # If kibana is in the list of services add its volume
    if [[ " ${services[@]} " =~ \\skibana\\s ]]; then
        local -r DEST_KIBANA_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/kibana/conf"
        mkdir -p "${DEST_KIBANA_CONF_DIRECTORY}"
        cp "${SRC_KIBANA_CONF_DIRECTORY}/*" "${DEST_KIBANA_CONF_DIRECTORY}"
    fi

}

main "$@"
