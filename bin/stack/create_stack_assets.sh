#!/usr/bin/env bash

############################################################################
# 
#  Copyright 2019 Crown Copyright
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# 
############################################################################

# Copies the necessary assets into the build

set -e

# shellcheck disable=SC1091
source lib/shell_utils.sh

download_file() {
  local -r dest_dir=$1
  local -r url_base=$2
  local -r filename=$3
  local -r new_filename="${4:-$filename}"

  echo -e "    Downloading ${BLUE}${url_base}/${filename}${NC}" \
    "${YELLOW}=>${NC} ${BLUE}${dest_dir}/${new_filename}${NC}"
      #--directory-prefix="${dest_dir}" \

  mkdir -p "${dest_dir}"
  wget \
    --quiet \
    --output-document="${dest_dir}/${new_filename}" \
    "${url_base}/${filename}"
  if [[ "${new_filename}" =~ .*\.sh$ ]]; then
    chmod u+x "${dest_dir}/${new_filename}"
  fi
}

copy_file() {
  local -r src=$1
  local -r dest_dir=$2
  local -r new_filename=$3
  # src may be a glob so we expand the glob and copy each file it represents
  # so we have visibility of what is being copied
  for src_file in ${src}; do
    echo -e "    Copying ${BLUE}${src_file}${NC} ${YELLOW}=>${NC} ${BLUE}${dest_dir}/${new_filename}${NC}"
    mkdir -p "${dest_dir}"
    if [ ! -e "${src_file}" ]; then
      echo -e "      ${RED}ERROR${NC}: File ${BLUE}${src_file}${NC} doesn't exist${NC}"
      exit 1
    fi
    cp "${src_file}" "${dest_dir}/${new_filename}"
  done
}

main() {
  setup_echo_colours

  [ "$#" -ge 2 ] || die "${RED}Error${NC}: Invalid arguments, usage:" \
    "${BLUE}build.sh stackName serviceX serviceY etc.${NC}"

  echo -e "${GREEN}Copying assets${NC}"

  # We need access to the release tags for downloading specific versions of files
  # from github
  # shellcheck disable=SC1091
  source container_versions.env

  local -r BUILD_STACK_NAME=$1
  local -r VERSION=$2
  local -r services=( "${@:3}" )
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${BUILD_STACK_NAME}-${VERSION}"
  local -r VOLUMES_DIRECTORY="${BUILD_DIRECTORY}/volumes"

  local -r SRC_CERTS_DIRECTORY="../../dev-resources/certs"
  local -r SRC_VOLUMES_DIRECTORY="../../dev-resources/compose/volumes"
  local -r SRC_NGINX_CONF_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/stroom-nginx/conf"
  local -r SRC_NGINX_HTML_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/stroom-nginx/html"
  local -r SRC_ELASTIC_CONF_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/elasticsearch/conf"
  local -r SRC_KIBANA_CONF_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/kibana/conf"
  local -r SRC_STROOM_LOG_SENDER_CONF_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/stroom-log-sender/conf"
  local -r SRC_STROOM_ALL_DBS_CONF_FILE="${SRC_VOLUMES_DIRECTORY}/stroom-all-dbs/conf/stroom-all-dbs.cnf"
  local -r SRC_STROOM_ALL_DBS_INIT_DIRECTORY="${SRC_VOLUMES_DIRECTORY}/stroom-all-dbs/init"
  local -r SRC_AUTH_UI_CONF_DIRECTORY="../../stroom-microservice-ui/template"
  local -r SEND_TO_STROOM_VERSION="send-to-stroom-v2.0"
  local -r SEND_TO_STROOM_URL_BASE="https://raw.githubusercontent.com/gchq/stroom-clients/${SEND_TO_STROOM_VERSION}/bash"
  local -r STROOM_CONFIG_YAML_URL_BASE="https://raw.githubusercontent.com/gchq/stroom/${STROOM_TAG}/stroom-app"
  local -r STROOM_CONFIG_YAML_SNAPSHOT_DIR="${LOCAL_STROOM_REPO_DIR:-UNKNOWN_LOCAL_STROOM_REPO_DIR}/stroom-app"
  local -r STROOM_CONFIG_YAML_FILENAME="prod.yml"
  local -r STROOM_PROXY_CONFIG_YAML_URL_BASE="https://raw.githubusercontent.com/gchq/stroom/${STROOM_PROXY_TAG}/stroom-app"
  local -r STROOM_PROXY_CONFIG_YAML_SNAPSHOT_DIR="${STROOM_CONFIG_YAML_SNAPSHOT_DIR}"
  local -r STROOM_PROXY_CONFIG_YAML_FILENAME="proxy-prod.yml"
  local -r STROOM_AUTH_SVC_CONFIG_YAML_URL_BASE="https://raw.githubusercontent.com/gchq/stroom-auth/${STROOM_AUTH_SERVICE_TAG}/stroom-auth-svc"
  local -r STROOM_AUTH_SVC_CONFIG_YAML_SNAPSHOT_DIR="${LOCAL_STROOM_AUTH_REPO_DIR:-UNKNOWN_LOCAL_STROOM_AUTH_REPO_DIR}/stroom-auth-svc"
  local -r STROOM_AUTH_SVC_CONFIG_YAML_FILENAME="config.yml"
  local -r CONFIG_FILENAME_IN_CONTAINER="config.yml"

  if element_in "stroom" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom${NC} config"
    local -r DEST_STROOM_CONFIG_DIRECTORY="${VOLUMES_DIRECTORY}/stroom/config"
    if [[ "${STROOM_TAG}" =~ local-SNAPSHOT ]]; then
      echo -e "    ${RED}WARNING${NC}: Copying a non-versioned local file because ${YELLOW}STROOM_TAG${NC}=${BLUE}${STROOM_TAG}${NC}"
      if [ ! -n "${LOCAL_STROOM_REPO_DIR}" ]; then
        echo -e "    ${RED}${NC}         Set ${YELLOW}LOCAL_STROOM_REPO_DIR${NC} to your local stroom repo"
      fi
      copy_file \
        "${STROOM_CONFIG_YAML_SNAPSHOT_DIR}/${STROOM_CONFIG_YAML_FILENAME}" \
        "${DEST_STROOM_CONFIG_DIRECTORY}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    else
      download_file \
        "${DEST_STROOM_CONFIG_DIRECTORY}" \
        "${STROOM_CONFIG_YAML_URL_BASE}" \
        "${STROOM_CONFIG_YAML_FILENAME}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    fi
  fi

  if element_in "stroom-proxy-remote" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-proxy-remote${NC} config"
    local -r DEST_STROOM_PROXY_REMOTE_CONFIG_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-proxy-remote/config"
    if [[ "${STROOM_PROXY_TAG}" =~ local-SNAPSHOT ]]; then
      echo -e "    ${RED}WARNING${NC}: Copying a non-versioned local file because ${YELLOW}STROOM_PROXY_TAG${NC}=${BLUE}${STROOM_PROXY_TAG}${NC}"
      if [ ! -n "${LOCAL_STROOM_REPO_DIR}" ]; then
        echo -e "    ${RED}${NC}         Set ${YELLOW}LOCAL_STROOM_REPO_DIR${NC} to your local stroom repo"
      fi
      copy_file \
        "${STROOM_PROXY_CONFIG_YAML_SNAPSHOT_DIR}/${STROOM_PROXY_CONFIG_YAML_FILENAME}" \
        "${DEST_STROOM_PROXY_REMOTE_CONFIG_DIRECTORY}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    else
      download_file \
        "${DEST_STROOM_PROXY_REMOTE_CONFIG_DIRECTORY}" \
        "${STROOM_PROXY_CONFIG_YAML_URL_BASE}" \
        "${STROOM_PROXY_CONFIG_YAML_FILENAME}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    fi

    echo -e "  Copying ${YELLOW}stroom-proxy-remote${NC} certificates"
    local -r DEST_PROXY_REMOTE_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-proxy-remote/certs"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.jks" \
      "${DEST_PROXY_REMOTE_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/client/client.jks" \
      "${DEST_PROXY_REMOTE_CERTS_DIRECTORY}"
  fi

  if element_in "stroom-proxy-local" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-proxy-local${NC} config"
    local -r DEST_STROOM_PROXY_LOCAL_CONFIG_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-proxy-local/config"
    if [[ "${STROOM_PROXY_TAG}" =~ local-SNAPSHOT ]]; then
      echo -e "    ${RED}WARNING${NC}: Copying a non-versioned local file because ${YELLOW}STROOM_PROXY_TAG${NC}=${BLUE}${STROOM_PROXY_TAG}${NC}"
      if [ ! -n "${LOCAL_STROOM_REPO_DIR}" ]; then
        echo -e "    ${RED}${NC}         Set ${YELLOW}LOCAL_STROOM_REPO_DIR${NC} to your local stroom repo"
      fi
      copy_file \
        "${STROOM_PROXY_CONFIG_YAML_SNAPSHOT_DIR}/${STROOM_PROXY_CONFIG_YAML_FILENAME}" \
        "${DEST_STROOM_PROXY_LOCAL_CONFIG_DIRECTORY}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    else
      download_file \
        "${DEST_STROOM_PROXY_LOCAL_CONFIG_DIRECTORY}" \
        "${STROOM_PROXY_CONFIG_YAML_URL_BASE}" \
        "${STROOM_PROXY_CONFIG_YAML_FILENAME}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    fi

    echo -e "  Copying ${YELLOW}stroom-proxy-local${NC} certificates"
    local -r DEST_PROXY_LOCAL_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-proxy-local/certs"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.jks" \
      "${DEST_PROXY_LOCAL_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/client/client.jks" \
      "${DEST_PROXY_LOCAL_CERTS_DIRECTORY}"
  fi

  if element_in "stroom-auth-service" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-auth-service${NC} config"
    local -r DEST_STROOM_AUTH_SERVICE_CONFIG_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-auth-service/config"
    if [[ "${STROOM_AUTH_SERVICE_TAG}" =~ local-SNAPSHOT ]]; then
      echo -e "    ${RED}WARNING${NC}: Copying a non-versioned local file because ${YELLOW}STROOM_AUTH_SERVICE_TAG${NC}=${BLUE}${STROOM_AUTH_SERVICE_TAG}${NC}"
      if [ ! -n "${LOCAL_STROOM_AUTH_REPO_DIR}" ]; then
        echo -e "    ${RED}${NC}         Set ${YELLOW}LOCAL_STROOM_AUTH_REPO_DIR${NC} to your local stroom repo"
      fi
      copy_file \
        "${STROOM_AUTH_SVC_CONFIG_YAML_SNAPSHOT_DIR}/${STROOM_AUTH_SVC_CONFIG_YAML_FILENAME}" \
        "${DEST_STROOM_AUTH_SERVICE_CONFIG_DIRECTORY}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    else
      download_file \
        "${DEST_STROOM_AUTH_SERVICE_CONFIG_DIRECTORY}" \
        "${STROOM_AUTH_SVC_CONFIG_YAML_URL_BASE}" \
        "${STROOM_AUTH_SVC_CONFIG_YAML_FILENAME}" \
        "${CONFIG_FILENAME_IN_CONTAINER}"
    fi
  fi

  if element_in "stroom-auth-ui" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-auth-ui${NC} certificates"
    local -r DEST_AUTH_UI_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-auth-ui/certs"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_AUTH_UI_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/server/server.pem.crt" \
      "${DEST_AUTH_UI_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/server/server.unencrypted.key" \
      "${DEST_AUTH_UI_CERTS_DIRECTORY}"

    echo -e "  Copying ${YELLOW}stroom-auth-ui${NC} config files"
    local -r DEST_AUTH_UI_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-auth-ui/conf"
    copy_file \
      "${SRC_AUTH_UI_CONF_DIRECTORY}/nginx.conf.template" \
      "${DEST_AUTH_UI_CONF_DIRECTORY}"
  fi

  if element_in "nginx" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}nginx${NC} certificates"
    local -r DEST_NGINX_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/certs"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_NGINX_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/server/server.pem.crt" \
      "${DEST_NGINX_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/server/server.unencrypted.key" \
      "${DEST_NGINX_CERTS_DIRECTORY}"

    echo -e "  Copying ${YELLOW}nginx${NC} config files"
    local -r DEST_NGINX_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/conf"
    copy_file \
      "${SRC_NGINX_CONF_DIRECTORY}/*.conf.template" \
      "${DEST_NGINX_CONF_DIRECTORY}"
    copy_file \
      "${SRC_NGINX_CONF_DIRECTORY}/crontab.txt" \
      "${DEST_NGINX_CONF_DIRECTORY}"

    echo -e "  Copying ${YELLOW}nginx${NC} html files"
    local -r DEST_NGINX_HTML_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/html"
    copy_file \
      "${SRC_NGINX_HTML_DIRECTORY}/50x.html" \
      "${DEST_NGINX_HTML_DIRECTORY}"
    copy_file \
      "${SRC_NGINX_HTML_DIRECTORY}/index.html" \
      "${DEST_NGINX_HTML_DIRECTORY}"
  fi

  if element_in "stroom" "${services[@]}" \
    || element_in "stroom-proxy-local" "${services[@]}" \
    || element_in "stroom-proxy-remote" "${services[@]}"; then

    # Set up the client certs needed for the send_data script
    echo -e "  Copying ${YELLOW}client${NC} certificates"
    local -r DEST_CLIENT_CERTS_DIRECTORY="${WORKING_DIRECTORY}/certs"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_CLIENT_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/client/client.pem.crt" \
      "${DEST_CLIENT_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/client/client.unencrypted.key" \
      "${DEST_CLIENT_CERTS_DIRECTORY}"

    # Get the send_to_stroom* scripts we need for the send_data script
    echo -e "  Copying ${YELLOW}send_to_stroom${NC} script"
    local -r DEST_LIB_DIR="${WORKING_DIRECTORY}/lib"
    download_file \
      "${DEST_LIB_DIR}" \
      "${SEND_TO_STROOM_URL_BASE}" \
      "send_to_stroom.sh"
    download_file \
      "${DEST_LIB_DIR}" \
      "${SEND_TO_STROOM_URL_BASE}" \
      "send_to_stroom_args.sh"
  fi

  # If elasticsearch is in the list of services add its volume
  if element_in "elasticsearch" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}elasticsearch${NC} config files"
    local -r DEST_ELASTIC_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/elasticsearch/conf"
    mkdir -p "${DEST_ELASTIC_CONF_DIRECTORY}"
    cp ${SRC_ELASTIC_CONF_DIRECTORY}/* "${DEST_ELASTIC_CONF_DIRECTORY}"
  fi

  # If stroom-log-sender is in the list of services add its volume
  if element_in "stroom-log-sender" "${services[@]}"; then

    echo -e "  Copying ${YELLOW}stroom-log-sender${NC} certificates"
    local -r DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-log-sender/certs"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/client/client.pem.crt" \
      "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"
    copy_file \
      "${SRC_CERTS_DIRECTORY}/client/client.unencrypted.key" \
      "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"

    echo -e "  Copying ${YELLOW}stroom-log-sender${NC} config files"
    local -r DEST_STROOM_LOG_SENDER_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-log-sender/conf"
    copy_file \
      "${SRC_STROOM_LOG_SENDER_CONF_DIRECTORY}/crontab.txt" \
      "${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}"
    copy_file \
      "${SRC_STROOM_LOG_SENDER_CONF_DIRECTORY}/crontab.env" \
      "${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}"
  fi

  if element_in "stroom-all-dbs" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-all-dbs${NC} config file"
    local -r DEST_STROOM_ALL_DBS_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-all-dbs/conf"
    copy_file "${SRC_STROOM_ALL_DBS_CONF_FILE}" "${DEST_STROOM_ALL_DBS_CONF_DIRECTORY}"

    echo -e "  Copying ${YELLOW}stroom-all-dbs${NC} init files"
    local -r DEST_STROOM_ALL_DBS_INIT_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-all-dbs/init"
    copy_file \
      "${SRC_STROOM_ALL_DBS_INIT_DIRECTORY}/000_init_override.sh" \
      "${DEST_STROOM_ALL_DBS_INIT_DIRECTORY}"
    copy_file \
      "${SRC_STROOM_ALL_DBS_INIT_DIRECTORY}/001_create_databases.sql.template" \
      "${DEST_STROOM_ALL_DBS_INIT_DIRECTORY}"
  fi


  # If kibana is in the list of services add its volume
  if element_in "kibana" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}kibana${NC} config files"
    local -r DEST_KIBANA_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/kibana/conf"
    mkdir -p "${DEST_KIBANA_CONF_DIRECTORY}"
    cp ${SRC_KIBANA_CONF_DIRECTORY}/* "${DEST_KIBANA_CONF_DIRECTORY}"
  fi

}

main "$@"
