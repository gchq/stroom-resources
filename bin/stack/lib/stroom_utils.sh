#!/bin/bash

setup_echo_colours

echo_healthy() {
  echo -e "  Status:   ${GREEN}HEALTHY${NC}"
}

echo_unhealthy() {
  echo -e "  Status:   ${RED}UNHEALTHY${NC}"
  echo -e "  Details:"
  echo
}

get_config_env_var() {
  local -r var_name="$1"
  # Use indirection to get value of the env var with this name
  local var_value="${!var_name}" 

  if [ -z "${var_value}" ]; then
    # Not set so try getting it from the yaml
    local -r yaml_file="${DIR}/config/${stack_name}.yml"

    local env_var_name_value
    env_var_name_value="$( \
      grep -v "\w* echo " "${yaml_file}" \
        | grep -v "^\w*#" \
        | grep -oP "(?<=\\$\\{)${var_name}[^}]+(?=\\})" \
        | head -n1 \
        | sed "s/:-/:/g" 
    )"
    var_value="${env_var_name_value#*:}"
  fi
  echo "${var_value}"
}

is_service_in_stack() {
  local -r service_name="$1"

  # return true if service_name is in the file
  # shellcheck disable=SC2151
  return grep -q "^${service_name}$" "${DIR}/SERVICES.txt"
}

check_service_health() {
  if [ $# -ne 4 ]; then
    echo -e "${RED}ERROR: ${NC}Invalid arguments. Usage: ${BLUE}health.sh HOST PORT PATH${NC}, e.g. health.sh localhost 8080 stroomAdmin"
    echo "$@"
    exit 1
  fi

  local -r health_check_service="$1"
  local -r health_check_host="$2"
  local -r health_check_port="$3"
  local -r health_check_path="$4"

  local -r health_check_url="http://${health_check_host}:${health_check_port}/${health_check_path}/healthcheck"
  local -r health_check_pretty_url="${health_check_url}?pretty=true"

  echo
  echo -e "Checking the health of ${GREEN}${health_check_service}${NC} using ${BLUE}${health_check_pretty_url}${NC}"

  local -r http_status_code=$(curl -s -o /dev/null -w "%{http_code}" "${health_check_url}")
  #echo "http_status_code: $http_status_code"

  # First hit the url to see if it is there
  if [ "x501" = "x${http_status_code}" ]; then
    # Server is up but no healthchecks are implmented, so assume healthy
    echo_healthy
  elif [ "x200" = "x${http_status_code}" ] || [ "x500" = "x${http_status_code}" ]; then
    # 500 code indicates at least one health check is unhealthy but jq will fish that out

    if [ "${is_jq_installed}" = true ]; then
      # Count all the unhealthy checks
      local -r unhealthy_count=$( \
      curl -s "${health_check_url}" | 
      jq '[to_entries[] | {key: .key, value: .value.healthy}] | map(select(.value == false)) | length')

      #echo "unhealthy_count: $unhealthy_count"
      if [ "${unhealthy_count}" -eq 0 ]; then
        echo_healthy
      else
        echo_unhealthy

        # Dump details of the failing health checks
        curl -s "${health_check_url}" | 
          jq 'to_entries | map(select(.value.healthy == false)) | from_entries'

        echo
        echo -e "  See ${BLUE}${health_check_url}?pretty=true${NC} for the full report"

        total_unhealthy_count=$((total_unhealthy_count + unhealthy_count))
      fi
    else
      # non-jq approach
      if [ "x200" = "x${http_status_code}" ]; then
        echo_healthy
      elif [ "x500" = "x${http_status_code}" ]; then
        echo_unhealthy
        echo -e "See ${BLUE}${health_check_pretty_url}${NC} for details"
        # Don't know how many are unhealthy but it is at least one
        total_unhealthy_count=$((total_unhealthy_count + 1))
      fi
    fi
  else
    echo_unhealthy
    local err_msg
    err_msg="$(curl -s --show-error "${health_check_url}" 2>&1)"
    echo -e "${RED}${err_msg}${NC}"
    total_unhealthy_count=$((total_unhealthy_count + 1))
  fi
}

check_service_health_if_in_stack() {
  local -r service_name="$1"
  local -r host="$2"
  local -r admin_port_var_name="$3"
  local -r admin_path="$4"

  if is_service_in_stack "${service_name}"; then
    local admin_port
    admin_port="$(get_config_env_var "${admin_port_var_name}")"

    check_service_health \
      "${service_name}" \
      "${host}" \
      "${admin_port}" \
      "${admin_path}"
  fi
}

check_overall_health() {

  local -r host="localhost"
  local total_unhealthy_count=0

  if command -v jq 1>/dev/null; then 
    # jq is available so do a more complex health check
    local is_jq_installed=true
  else
    # jq is not available so do a simple health check
    echo -e "\n${YELLOW}Warning${NC}: Doing simple health check as ${BLUE}jq${NC} is not installed."
    echo -e "See ${BLUE}https://stedolan.github.io/jq/${NC} for details on how to install it."
    local is_jq_installed=false
  fi 

  # TODO change to use check_service_health_if_in_stack
  check_service_health "stroom" "${host}" "${STROOM_ADMIN_PORT}" "stroomAdmin"
  check_service_health "stroom-proxy-remote" "${host}" "${STROOM_PROXY_REMOTE_ADMIN_PORT}" "proxyAdmin"
  check_service_health "stroom-proxy-local" "${host}" "${STROOM_PROXY_LOCAL_ADMIN_PORT}" "proxyAdmin"
  check_service_health "stroom-auth-service" "${host}" "${STROOM_AUTH_SERVICE_ADMIN_PORT}" "authenticationServiceAdmin"

  if [[ ! -z ${STROOM_STATS_SERVICE_ADMIN_PORT} ]]; then
    check_service_health "stroom-stats" "${host}" "${STROOM_STATS_SERVICE_ADMIN_PORT}" "statsAdmin"
  fi

  echo
  if [ "${total_unhealthy_count}" -eq 0 ]; then
    echo -e "Overall system health: ${GREEN}HEALTHY${NC}"
  else
    echo -e "Overall system health: ${RED}UNHEALTHY${NC}"
  fi

  return ${total_unhealthy_count}
}

echo_info_line() {
  # Echos a line like "  PADDED_STRING                    UNPADDED_STRING"

  local -r padding=$1
  local -r padded_string=$2
  local -r unpadded_string=$3
  # Uses bash substitution to only print the part of padding beyond the length of padded_string
  printf "  ${GREEN}%s${NC} %s${BLUE}${unpadded_string}${NC}\n" "${padded_string}" "${padding:${#padded_string}}"
}

display_stack_info() {
  # see if the terminal supports colors...
  no_of_colours=$(tput colors)

  if [ ! "${MONOCHROME}" = true ]; then
    if test -n "$no_of_colours" && test "${no_of_colours}" -eq 256; then
      # 256 colours so print the stroom banner in dirty orange
      echo -en "\e[38;5;202m"
    else
      # No 256 colour support so fall back to blue
      echo -en "${BLUE}"
    fi
  fi
  cat "${DIR}"/lib/banner.txt
  echo -en "${NC}"

  echo
  echo -e "Stack image versions:"
  echo

  # Used for right padding 
  local -r padding="                            "

  while read -r line; do
    local image_name="${line%%:*}"
    local image_version="${line#*=}"
    echo_info_line "${padding}" "${image_name}" "${image_version}"
  done < "${DIR}"/VERSIONS.txt

  echo
  echo -e "The following admin pages are available"
  echo
  echo_info_line "${padding}" "Stroom" "http://localhost:${STROOM_ADMIN_PORT}/stroomAdmin"

  if [[ ! -z ${STROOM_STATS_SERVICE_ADMIN_PORT} ]]; then
    echo_info_line "${padding}" "Stroom Stats" "http://localhost:${STROOM_STATS_SERVICE_ADMIN_PORT}/statsAdmin"
  fi

  echo_info_line "${padding}" "Stroom Proxy (local)" "http://localhost:${STROOM_PROXY_LOCAL_ADMIN_PORT}/proxyAdmin"
  echo_info_line "${padding}" "Stroom Proxy (remote)" "http://localhost:${STROOM_PROXY_REMOTE_ADMIN_PORT}/proxyAdmin"
  echo_info_line "${padding}" "Stroom Auth" "http://localhost:${STROOM_AUTH_SERVICE_ADMIN_PORT}/authenticationServiceAdmin"

  echo
  echo -e "Data can be POSTed to Stroom using the following URLs (see README for details)"
  echo
  echo_info_line "${padding}" "Stroom (direct)" "https://localhost/stroom/datafeed"
  echo_info_line "${padding}" "Stroom Proxy (local)" "https://localhost:${STROOM_PROXY_LOCAL_HTTPS_APP_PORT}/stroom/datafeed"
  echo_info_line "${padding}" "Stroom Proxy (remote)" "https://localhost:${STROOM_PROXY_REMOTE_HTTPS_APP_PORT}/stroom/datafeed"

  echo
  echo -e "The Stroom user interface can be accessed at the following URL"
  echo
  echo_info_line "${padding}" "Stroom UI" "https://localhost/stroom"
  echo
  echo -e "  (Login with the default username/password: ${BLUE}admin${NC}/${BLUE}admin${NC})"
  echo
}

start_stack() {
  check_arg_count_at_least 1 "$@"
  local -r stack_name="$1"
  # These lines may help in debugging the config that is passed to the containers
  #env
  #docker-compose -f "$DIR"/config/"${stack_name}".yml config

  echo -e "${GREEN}Creating and starting the docker containers and volumes${NC}"
  echo

  # Capture the hostname/ip of the host running the containers so they can
  # make it available to stroom-log-sender
  # shellcheck disable=SC2034
  DOCKER_HOST_HOSTNAME="$(hostname -f)"
  # shellcheck disable=SC2034
  DOCKER_HOST_IP="${HOST_IP}"

  # shellcheck disable=SC2094
  docker-compose \
    --project-name "${stack_name}" \
    -f "$DIR/config/${stack_name}.yml" \
    up \
    -d \
    "${@:2}"
}

stop_service_if_in_stack() {
  check_arg_count 2 "$@"
  local -r stack_name="$1"
  local -r service_name="$2"

  echo -e "${GREEN}Stopping container ${BLUE}${service_name}${NC}"

  local -r state="$(docker inspect -f '{{.State.Running}}' "${service_name}")"

  if [ "${state}" = "true" ]; then
    # shellcheck disable=SC2094
    docker-compose \
      --project-name "${stack_name}" \
      -f "$DIR"/config/"${stack_name}".yml \
      stop \
      "${service_name}"
  else
    echo -e "Container ${BLUE}${service_name}${NC} is not running"
  fi
}

stop_stack() {
  check_arg_count 1 "$@"
  local -r stack_name="$1"
  echo -e "${GREEN}Stopping the docker containers in graceful order${NC}"
  echo

  # Order is critical here for a graceful shutdown
  stop_service_if_in_stack "${stack_name}" "stroom-log-sender"
  stop_service_if_in_stack "${stack_name}" "stroom-proxy-remote"
  stop_service_if_in_stack "${stack_name}" "stroom-proxy-local"
  stop_service_if_in_stack "${stack_name}" "nginx"
  stop_service_if_in_stack "${stack_name}" "stroom-auth-ui"
  stop_service_if_in_stack "${stack_name}" "stroom-auth-service"
  stop_service_if_in_stack "${stack_name}" "stroom"
  stop_service_if_in_stack "${stack_name}" "stroom-all-dbs"

  # In case we have missed any stop the whole project
  echo -e "${GREEN}Stopping any remaining containers in the stack${NC}"
  # shellcheck disable=SC2094
  docker-compose \
    --project-name "${stack_name}" \
    -f "$DIR/config/${stack_name}.yml" \
    stop
}
