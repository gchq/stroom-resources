#!/usr/bin/env bash
#
# Copies the necessary assets into the build

source lib/shell.sh

main() {
    setup_echo_colours
    echo -e "${GREEN}Copying assets${NC}"
    
    readonly local STACK_NAME=$1
    readonly local BUILD_FOLDER='build'
    readonly local WORKING_DIRECTORY="$BUILD_FOLDER/$STACK_NAME"

    readonly local SRC_CERTS_DIRECTORY="../../dev-resources/certs/server"
    readonly local SRC_NGINX_CONF_DIRECTORY="../../stroom-nginx/template"
    readonly local SRC_AUTH_UI_CONF_DIRECTORY="../../stroom-microservice-ui/template"

    setup_echo_colours

    readonly local DEST_AUTH_UI_CERTS_DIRECTORY="$WORKING_DIRECTORY/volumes/auth-ui/certs"
    mkdir -p "$DEST_AUTH_UI_CERTS_DIRECTORY"
    cp $SRC_CERTS_DIRECTORY/* $DEST_AUTH_UI_CERTS_DIRECTORY

    readonly local DEST_AUTH_UI_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/auth-ui/conf"
    mkdir -p "$DEST_AUTH_UI_CONF_DIRECTORY"
    cp $SRC_AUTH_UI_CONF_DIRECTORY/* $DEST_AUTH_UI_CONF_DIRECTORY

    readonly local DEST_NGINX_CERTS_DIRECTORY="$WORKING_DIRECTORY/volumes/nginx/certs"
    mkdir -p "$DEST_NGINX_CERTS_DIRECTORY"
    cp $SRC_CERTS_DIRECTORY/* $DEST_NGINX_CERTS_DIRECTORY

    readonly local DEST_NGINX_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/nginx/conf"
    mkdir -p "$DEST_NGINX_CONF_DIRECTORY"
    cp $SRC_NGINX_CONF_DIRECTORY/* $DEST_NGINX_CONF_DIRECTORY

}

main "$@"