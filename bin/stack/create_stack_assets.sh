#!/usr/bin/env bash
#
# Copies the necessary assets into the build

source lib/shell_utils.sh

main() {
    setup_echo_colours

    [ "$#" -ge 2 ] || die "${RED}Error${NC}: Invalid arguments, usage: ${BLUE}build.sh stackName serviceX serviceY etc.${NC}"

    local -r services="${@:2}"

    echo -e "${GREEN}Copying assets${NC}"

    local -r STACK_NAME=$1
    local -r BUILD_FOLDER='build'
    local -r WORKING_DIRECTORY="$BUILD_FOLDER/$STACK_NAME"

    local -r SRC_CERTS_DIRECTORY="../../dev-resources/certs/server"
    local -r SRC_NGINX_CONF_DIRECTORY="../../stroom-nginx/template"
    local -r SRC_ELASTIC_CONF_DIRECTORY="../compose/volumes/elasticsearch/conf"
    local -r SRC_KIBANA_CONF_DIRECTORY="../compose/volumes/kibana/conf"
    local -r SRC_AUTH_UI_CONF_DIRECTORY="../../stroom-microservice-ui/template"

    local -r DEST_AUTH_UI_CERTS_DIRECTORY="$WORKING_DIRECTORY/volumes/auth-ui/certs"
    mkdir -p "$DEST_AUTH_UI_CERTS_DIRECTORY"
    cp $SRC_CERTS_DIRECTORY/ca.pem.crt $DEST_AUTH_UI_CERTS_DIRECTORY
    cp $SRC_CERTS_DIRECTORY/server.pem.crt $DEST_AUTH_UI_CERTS_DIRECTORY
    cp $SRC_CERTS_DIRECTORY/server.unencrypted.key $DEST_AUTH_UI_CERTS_DIRECTORY

    local -r DEST_AUTH_UI_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/auth-ui/conf"
    mkdir -p "$DEST_AUTH_UI_CONF_DIRECTORY"
    cp $SRC_AUTH_UI_CONF_DIRECTORY/* $DEST_AUTH_UI_CONF_DIRECTORY

    local -r DEST_NGINX_CERTS_DIRECTORY="$WORKING_DIRECTORY/volumes/nginx/certs"
    mkdir -p "$DEST_NGINX_CERTS_DIRECTORY"
    cp $SRC_CERTS_DIRECTORY/ca.pem.crt $DEST_NGINX_CERTS_DIRECTORY
    cp $SRC_CERTS_DIRECTORY/server.pem.crt $DEST_NGINX_CERTS_DIRECTORY
    cp $SRC_CERTS_DIRECTORY/server.unencrypted.key $DEST_NGINX_CERTS_DIRECTORY

    local -r DEST_NGINX_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/nginx/conf"
    mkdir -p "$DEST_NGINX_CONF_DIRECTORY"
    cp $SRC_NGINX_CONF_DIRECTORY/* $DEST_NGINX_CONF_DIRECTORY

    # If elasticsearch is in the list of services add its volume
    if [[ " ${services[@]} " =~ " elasticsearch " ]]; then
        local -r DEST_ELASTIC_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/elasticsearch/conf"
        mkdir -p "$DEST_ELASTIC_CONF_DIRECTORY"
        cp $SRC_ELASTIC_CONF_DIRECTORY/* $DEST_ELASTIC_CONF_DIRECTORY
    fi

    # If kibana is in the list of services add its volume
    if [[ " ${services[@]} " =~ " kibana " ]]; then
        local -r DEST_KIBANA_CONF_DIRECTORY="$WORKING_DIRECTORY/volumes/kibana/conf"
        mkdir -p "$DEST_KIBANA_CONF_DIRECTORY"
        cp $SRC_KIBANA_CONF_DIRECTORY/* $DEST_KIBANA_CONF_DIRECTORY
    fi

}

main "$@"
