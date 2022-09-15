#!/bin/bash

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

# Docker changed from using a separate docker-compose command to compose
# being a sub-comand to the docker command. Thus we need to work out what
# is installed and use the appropriate command by setting a constant.
set_docker_compose_cmd() {
  if [[ -z "${DOCKER_COMPOSE_CMD}" ]]; then
    DOCKER_COMPOSE_CMD=
    if command -v docker; then
      if docker compose version 2>/dev/null || true \
          | grep -E -q "^Docker Compose version [0-9.]+"; then
        # Docker with the compose plugin is available
        # Use --compatibility due to the way compose names its services
        DOCKER_COMPOSE_CMD="docker compose --compatibility"
        # '-' vs '_'
      else
        if command -v docker-compose 1>/dev/null; then 
          # Legacy docker-compose command is available so use that
          DOCKER_COMPOSE_CMD="docker-compose"
        else
          echo -e "${RED}ERROR${NC}: Docker Compose is not installed!"
          echo -e "See ${BLUE}https://docs.docker.com/compose/install/${NC} for" \
            "details on how to install it"
          echo -e "Version ${BLUE}1.23.1${NC} or higher is required"
          exit 1
        fi
      fi
    else
      # No docker installed
      echo -e "${RED}ERROR${NC}: Docker engine is not installed!"
      echo -e "See ${BLUE}https://docs.docker.com/engine/install/#server${NC}" \
        "for details on how to install it"
      echo -e "Version ${BLUE}17.12.0${NC} or higher is required"
      exit 1
    fi
  fi
}

# shellcheck disable=SC2034
{
  MONOCHROME=false
  QUIET_MODE=false
  STACK_SERVICES_FILENAME="ACTIVE_SERVICES.txt"
  ALL_SERVICES_FILENAME="ALL_SERVICES.txt"
  LOGS_DIR_NAME="logs"

  SERVICES_WITH_HEALTH_CHECK=(
      "stroom"
      "stroom-stats"
      "stroom-proxy-local"
      "stroom-proxy-remote"
  )

  SERVICE_SHUTDOWN_ORDER=(
    "stroom-log-sender"
    "stroom-proxy-remote"
    "stroom-proxy-local"
    "nginx"
    "stroom-ui"
    "stroom"
    "stroom-stats"
    "stroom-all-dbs"
    "kafka"
    "hbase"
    "zookeeper"
    "hdfs"
  )
  
  # Bash 4 associative array or service names to DropWiz admin path names
  declare -A ADMIN_PATH_NAMES_MAP=(
      ["stroom"]="stroomAdmin"
      ["stroom-auth-service"]="authenticationServiceAdmin"
      ["stroom-stats"]="statsAdmin"
      ["stroom-proxy-local"]="proxyAdmin"
      ["stroom-proxy-remote"]="proxyAdmin"
  )

  declare -A ADMIN_PORT_ENV_VAR_NAMES_MAP=(
      ["stroom"]="STROOM_ADMIN_PORT"
      ["stroom-auth-service"]="STROOM_AUTH_SERVICE_ADMIN_PORT"
      ["stroom-stats"]="STROOM_STATS_SERVICE_ADMIN_PORT"
      ["stroom-proxy-local"]="STROOM_PROXY_LOCAL_ADMIN_PORT"
      ["stroom-proxy-remote"]="STROOM_PROXY_REMOTE_ADMIN_PORT"
  )

  declare -A SERVICE_NAMES_MAP=(
    ["stroom-log-sender"]="Stroom Log Sender"
    ["stroom-proxy-remote"]="Stroom Proxy (remote)"
    ["stroom-proxy-local"]="Stroom Proxy (local)"
    ["nginx"]="Nginx"
    ["stroom-auth-ui"]="Stroom Authentication UI"
    ["stroom-auth-service"]="Stroom Authentication Service"
    ["stroom"]="Stroom"
    ["stroom-stats"]="Stroom Stats"
    ["stroom-all-dbs"]="Stroom Databases"
    ["kafka"]="Kafa"
    ["hbase"]="HBase"
    ["zookeeper"]="Zookeeper"
    ["hdfs"]="HDFS"
  )

  set_docker_compose_cmd
}
