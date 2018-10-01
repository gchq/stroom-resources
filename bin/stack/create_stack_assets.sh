#!/usr/bin/env bash
#
# Copies the necessary assets into the build

source lib/shell_utils.sh

main() {
    setup_echo_colours
    echo -e "${GREEN}Copying assets${NC}"

    local -r STACK_NAME=$1
    local -r BUILD_FOLDER='build'
    local -r WORKING_DIRECTORY="$BUILD_FOLDER/$STACK_NAME"

    local -r SRC_CERTS_DIRECTORY="../../dev-resources/certs/server"
    local -r SRC_NGINX_CONF_DIRECTORY="../../stroom-nginx/template"
    local -r SRC_AUTH_UI_CONF_DIRECTORY="../../stroom-microservice-ui/template"

    setup_echo_colours

    local -r DEST_AUTH_UI_CERTS_DIRECTORY="$WORKING_DIRECTORY/volumes/auth-ui/certs"
    mkdir -p "$DEST_AUTH_UI_CERTS_DIRECTORY"
    cp $SRC_CERTS_DIRECTORY/* $DEST_AUTH_UI_CERTS_DIRECTORY

    local -r DEST_AUTH_UI_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/auth-ui/conf"
    mkdir -p "$DEST_AUTH_UI_CONF_DIRECTORY"
    cp $SRC_AUTH_UI_CONF_DIRECTORY/* $DEST_AUTH_UI_CONF_DIRECTORY

    local -r DEST_NGINX_CERTS_DIRECTORY="$WORKING_DIRECTORY/volumes/nginx/certs"
    mkdir -p "$DEST_NGINX_CERTS_DIRECTORY"
    cp $SRC_CERTS_DIRECTORY/* $DEST_NGINX_CERTS_DIRECTORY

    local -r DEST_NGINX_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/nginx/conf"
    mkdir -p "$DEST_NGINX_CONF_DIRECTORY"
    cp $SRC_NGINX_CONF_DIRECTORY/* $DEST_NGINX_CONF_DIRECTORY

}

main "$@"
