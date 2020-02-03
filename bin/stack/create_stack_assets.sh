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

copy_file_to_dir() {
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

delete_file() {
  local file="$1"; shift

  echo -e "    Deleting file ${BLUE}${file}${NC}"
  if [ ! -e "${file}" ]; then
    echo -e "      ${RED}ERROR${NC}: File ${BLUE}${file}${NC} doesn't exist${NC}"
    exit 1
  fi
  rm "${file}"
}

# Removes blocks of conditional content in a file if the content is for a
# service that is not in the stack, e.g. 
# 
#   X=Y
#   # ------------IF_stroom_IN_STACK------------
#   STROOM_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom"
#   # ------------FI_stroom_IN_STACK------------
#   Y=Z
#
# becomes (if stroom is not in the services array)
# 
#   X=Y
#   Y=Z
remove_conditional_content() {
  local file="$1"; shift

  [ -f "${file}" ] \
    || echo -e "      ${RED}ERROR${NC}: File ${BLUE}${file}${NC} doesn't exist${NC}"

  local cond_content_service_regex="(?<=IF_)[^_]+(?=_IN_STACK)"

  while read -r cond_content_service_name; do
    if ! element_in "${cond_content_service_name}" "${services[@]}"; then
      # This content is for a service that is NOT in the stack, so remove it
      echo -e "      Removing conditional content for" \
        "${YELLOW}${cond_content_service_name}${NC} in ${BLUE}${file}${NC}"

      local block_start_regex="IF_${cond_content_service_name}_IN_STACK"
      local block_end_regex="FI_${cond_content_service_name}_IN_STACK"

      # Delete from the start pattern (inc.) to the end pattern (inc.)
      # It will delete multiple blocks for this service
      sed -i "/${block_start_regex}/,/${block_end_regex}/d" "${file}"
    fi
  done < <( \
    grep -oP "${cond_content_service_regex}" "${file}"  \
    | sort  \
    | uniq \
  )

  # All remaining conditional blocks are now valid for our services so
  # remove the IF_ and FI_ tags
  sed -i -r "/(IF|FI)_[^_]+_IN_STACK/d" "${file}"
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
        echo -e "    ${RED}${NC}         E.g. '${BLUE}export LOCAL_STROOM_REPO_DIR=/home/dev/git_work/stroom${NC}'"
      fi
      copy_file_to_dir \
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

  #########################
  #  stroom-remote-proxy  #
  #########################

  if element_in "stroom-proxy-remote" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-proxy-remote${NC} config"
    local -r DEST_STROOM_PROXY_REMOTE_CONFIG_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-proxy-remote/config"
    if [[ "${STROOM_PROXY_TAG}" =~ local-SNAPSHOT ]]; then
      echo -e "    ${RED}WARNING${NC}: Copying a non-versioned local file because ${YELLOW}STROOM_PROXY_TAG${NC}=${BLUE}${STROOM_PROXY_TAG}${NC}"
      if [ ! -n "${LOCAL_STROOM_REPO_DIR}" ]; then
        echo -e "    ${RED}${NC}         Set ${YELLOW}LOCAL_STROOM_REPO_DIR${NC} to your local stroom repo"
        echo -e "    ${RED}${NC}         E.g. '${BLUE}export LOCAL_STROOM_REPO_DIR=/home/dev/git_work/stroom${NC}'"
      fi
      copy_file_to_dir \
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
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.jks" \
      "${DEST_PROXY_REMOTE_CERTS_DIRECTORY}"
    # client keystore so it can forward to stroom(?:-proxy)? and make
    # rest calls
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/client/client.jks" \
      "${DEST_PROXY_REMOTE_CERTS_DIRECTORY}"
  fi

  ########################
  #  stroom-proxy-local  #
  ########################

  if element_in "stroom-proxy-local" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-proxy-local${NC} config"
    local -r DEST_STROOM_PROXY_LOCAL_CONFIG_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-proxy-local/config"
    if [[ "${STROOM_PROXY_TAG}" =~ local-SNAPSHOT ]]; then
      echo -e "    ${RED}WARNING${NC}: Copying a non-versioned local file because ${YELLOW}STROOM_PROXY_TAG${NC}=${BLUE}${STROOM_PROXY_TAG}${NC}"
      if [ ! -n "${LOCAL_STROOM_REPO_DIR}" ]; then
        echo -e "    ${RED}${NC}         Set ${YELLOW}LOCAL_STROOM_REPO_DIR${NC} to your local stroom repo"
        echo -e "    ${RED}${NC}         E.g. '${BLUE}export LOCAL_STROOM_REPO_DIR=/home/dev/git_work/stroom${NC}'"
      fi
      copy_file_to_dir \
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
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.jks" \
      "${DEST_PROXY_LOCAL_CERTS_DIRECTORY}"
    # client keystore so it can forward to stroom(?:-proxy)? and make
    # rest calls
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/client/client.jks" \
      "${DEST_PROXY_LOCAL_CERTS_DIRECTORY}"
  fi

  #########################
  #  stroom-auth-service  #
  #########################

  if element_in "stroom-auth-service" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-auth-service${NC} config"
    local -r DEST_STROOM_AUTH_SERVICE_CONFIG_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-auth-service/config"
    if [[ "${STROOM_AUTH_SERVICE_TAG}" =~ local-SNAPSHOT ]]; then
      echo -e "    ${RED}WARNING${NC}: Copying a non-versioned local file because ${YELLOW}STROOM_AUTH_SERVICE_TAG${NC}=${BLUE}${STROOM_AUTH_SERVICE_TAG}${NC}"
      if [ ! -n "${LOCAL_STROOM_AUTH_REPO_DIR}" ]; then
        echo -e "    ${RED}${NC}         Set ${YELLOW}LOCAL_STROOM_AUTH_REPO_DIR${NC} to your local stroom repo"
        echo -e "    ${RED}${NC}         E.g. '${BLUE}export LOCAL_STROOM_REPO_DIR=/home/dev/git_work/stroom${NC}'"
      fi
      copy_file_to_dir \
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

  ####################
  #  stroom-auth-ui  #
  ####################

  if element_in "stroom-auth-ui" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-auth-ui${NC} certificates"
    local -r DEST_AUTH_UI_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-auth-ui/certs"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_AUTH_UI_CERTS_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/server/server.pem.crt" \
      "${DEST_AUTH_UI_CERTS_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/server/server.unencrypted.key" \
      "${DEST_AUTH_UI_CERTS_DIRECTORY}"

    echo -e "  Copying ${YELLOW}stroom-auth-ui${NC} config files"
    local -r DEST_AUTH_UI_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-auth-ui/conf"
    copy_file_to_dir \
      "${SRC_AUTH_UI_CONF_DIRECTORY}/nginx.conf.template" \
      "${DEST_AUTH_UI_CONF_DIRECTORY}"
  fi

  ###########
  #  nginx  #
  ###########
  
  if element_in "nginx" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}nginx${NC} certificates"
    local -r DEST_NGINX_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/certs"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_NGINX_CERTS_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/server/server.pem.crt" \
      "${DEST_NGINX_CERTS_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/server/server.unencrypted.key" \
      "${DEST_NGINX_CERTS_DIRECTORY}"

    echo -e "  Copying ${YELLOW}nginx${NC} config files"
    local -r DEST_NGINX_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/conf"
    copy_file_to_dir \
      "${SRC_NGINX_CONF_DIRECTORY}/*.conf.template" \
      "${DEST_NGINX_CONF_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_NGINX_CONF_DIRECTORY}/crontab.txt" \
      "${DEST_NGINX_CONF_DIRECTORY}"

    # We need a custom nginx.conf for the stroom_proxy stack as that is just
    # proxy and nginx.
    if [ "${BUILD_STACK_NAME}" = "stroom_proxy" ]; then
      echo -e "  Overriding ${YELLOW}stroom-nginx${NC} configuration for stroom_proxy stack"
      copy_file_to_dir \
        "${SRC_NGINX_CONF_DIRECTORY}/custom/proxy_nginx.conf.template" \
        "${DEST_NGINX_CONF_DIRECTORY}" \
        "nginx.conf.template"

      # Remove files not applicable to the remote proxy stack
      delete_file \
        "${DEST_NGINX_CONF_DIRECTORY}/locations.stroom.conf.template" 
      delete_file \
        "${DEST_NGINX_CONF_DIRECTORY}/upstreams.stroom.processing.conf.template" 
      delete_file \
        "${DEST_NGINX_CONF_DIRECTORY}/upstreams.stroom.ui.conf.template" 
      delete_file \
        "${DEST_NGINX_CONF_DIRECTORY}/locations.auth.conf.template" 
      delete_file \
        "${DEST_NGINX_CONF_DIRECTORY}/upstreams.auth.service.conf.template" 
      delete_file \
        "${DEST_NGINX_CONF_DIRECTORY}/upstreams.auth.ui.conf.template" 
    fi

    # Delete the dev conf file as this is not applicable to a released
    # stack
    delete_file \
      "${DEST_NGINX_CONF_DIRECTORY}/locations.dev.conf.template" 

    # Remove the reference to the dev locations file
    remove_conditional_content \
      "${DEST_NGINX_CONF_DIRECTORY}/nginx.conf.template" 

    echo -e "  Copying ${YELLOW}nginx${NC} html files"
    local -r DEST_NGINX_HTML_DIRECTORY="${VOLUMES_DIRECTORY}/nginx/html"
    copy_file_to_dir \
      "${SRC_NGINX_HTML_DIRECTORY}/50x.html" \
      "${DEST_NGINX_HTML_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_NGINX_HTML_DIRECTORY}/index.html" \
      "${DEST_NGINX_HTML_DIRECTORY}"
  fi

  #############################
  #  stroom / stroom-proxy-*  #
  #############################
  
  if element_in "stroom" "${services[@]}" \
    || element_in "stroom-proxy-local" "${services[@]}" \
    || element_in "stroom-proxy-remote" "${services[@]}"; then

    # Set up the client certs needed for the send_data script
    echo -e "  Copying ${YELLOW}client${NC} certificates"
    local -r DEST_CLIENT_CERTS_DIRECTORY="${WORKING_DIRECTORY}/certs"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_CLIENT_CERTS_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/client/client.pem.crt" \
      "${DEST_CLIENT_CERTS_DIRECTORY}"
    copy_file_to_dir \
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

  ####################
  #  elastic-search  #
  ####################
  
  # If elasticsearch is in the list of services add its volume
  if element_in "elasticsearch" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}elasticsearch${NC} config files"
    local -r DEST_ELASTIC_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/elasticsearch/conf"
    mkdir -p "${DEST_ELASTIC_CONF_DIRECTORY}"
    cp ${SRC_ELASTIC_CONF_DIRECTORY}/* "${DEST_ELASTIC_CONF_DIRECTORY}"
  fi

  #######################
  #  stroom-log-sender  #
  #######################
  
  # If stroom-log-sender is in the list of services add its volume
  if element_in "stroom-log-sender" "${services[@]}"; then

    echo -e "  Copying ${YELLOW}stroom-log-sender${NC} certificates"
    local -r DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-log-sender/certs"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/certificate-authority/ca.pem.crt" \
      "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/client/client.pem.crt" \
      "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_CERTS_DIRECTORY}/client/client.unencrypted.key" \
      "${DEST_STROOM_LOG_SENDER_CERTS_DIRECTORY}"

    echo -e "  Copying ${YELLOW}stroom-log-sender${NC} config files"
    local -r DEST_STROOM_LOG_SENDER_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-log-sender/conf"
    copy_file_to_dir \
      "${SRC_STROOM_LOG_SENDER_CONF_DIRECTORY}/crontab.txt" \
      "${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}"

    # TODO don't think we need this with supercronic
    #remove_conditional_content "${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}/crontab.txt"

    #copy_file_to_dir \
      #"${SRC_STROOM_LOG_SENDER_CONF_DIRECTORY}/crontab.env" \
      #"${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}"
    #remove_conditional_content "${DEST_STROOM_LOG_SENDER_CONF_DIRECTORY}/crontab.env"
  fi

  ####################
  #  stroom-all-dbs  #
  ####################
  
  if element_in "stroom-all-dbs" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}stroom-all-dbs${NC} config file"
    local -r DEST_STROOM_ALL_DBS_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-all-dbs/conf"
    copy_file_to_dir "${SRC_STROOM_ALL_DBS_CONF_FILE}" "${DEST_STROOM_ALL_DBS_CONF_DIRECTORY}"

    echo -e "  Copying ${YELLOW}stroom-all-dbs${NC} init files"
    local -r DEST_STROOM_ALL_DBS_INIT_DIRECTORY="${VOLUMES_DIRECTORY}/stroom-all-dbs/init"
    copy_file_to_dir \
      "${SRC_STROOM_ALL_DBS_INIT_DIRECTORY}/000_init_override.sh" \
      "${DEST_STROOM_ALL_DBS_INIT_DIRECTORY}"
    copy_file_to_dir \
      "${SRC_STROOM_ALL_DBS_INIT_DIRECTORY}/001_create_databases.sql.template" \
      "${DEST_STROOM_ALL_DBS_INIT_DIRECTORY}"
  fi

  ############
  #  kibana  #
  ############

  # If kibana is in the list of services add its volume
  if element_in "kibana" "${services[@]}"; then
    echo -e "  Copying ${YELLOW}kibana${NC} config files"
    local -r DEST_KIBANA_CONF_DIRECTORY="${VOLUMES_DIRECTORY}/kibana/conf"
    mkdir -p "${DEST_KIBANA_CONF_DIRECTORY}"
    cp ${SRC_KIBANA_CONF_DIRECTORY}/* "${DEST_KIBANA_CONF_DIRECTORY}"
  fi

}

main "$@"
