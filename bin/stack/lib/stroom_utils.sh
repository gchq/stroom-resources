#!/bin/bash

setup_echo_colours

# shellcheck disable=SC1090
#{
  #source "$DIR"/lib/stroom_utils.sh
#}

stack_services_file="SERVICES.txt"

SERVICES_WITH_HEALTH_CHECK=(
    "stroom"
    "stroom-auth-service"
    "stroom-stats"
    "stroom-proxy-local"
    "stroom-proxy-remote"
)

SERVICE_SHUTDOWN_ORDER=(
  "stroom-log-sender"
  "stroom-proxy-remote"
  "stroom-proxy-local"
  "nginx"
  "stroom-auth-ui"
  "stroom-auth-service"
  "stroom"
  "stroom-stats"
  "stroom-all-dbs"
  "kafka"
  "hbase"
  "zookeeper"
  "hdfs"
)

echo_running() {
  echo -e "  Status:   ${GREEN}RUNNING${NC}"
}

echo_stopped() {
  echo -e "  Status:   ${RED}STOPPED${NC}"
}

echo_doesnt_exist() {
  echo -e "  Status:   ${RED}NO CONTAINER${NC}"
}

echo_healthy() {
  echo -e "  Status:   ${GREEN}HEALTHY${NC}"
}

echo_unhealthy() {
  echo -e "  Status:   ${RED}UNHEALTHY${NC}"
  echo -e "  Details:"
  echo
}

show_services_usage_part() {
  # shellcheck disable=SC2002
  if [ -f "${DIR}/${stack_services_file}" ] \
    && [ "$(cat "${DIR}/${stack_services_file}" | wc -l)" -gt 0 ]; then

    echo -e "Valid SERVICE values:"
    while read -r service; do
      echo -e "  ${service}"
    done < "${DIR}/${stack_services_file}"
  fi
}

show_default_usage() {
  local specific_args="$1"
  local specific_msg="$2"
  # specific_options must be a single line or the sort below will break it
  local specific_options="$3"
  echo -e "Usage: $(basename "$0") [OPTION]... ${specific_args}"
  if [ -n "${specific_msg}" ]; then
    echo -e "${specific_msg}"
  fi
  echo -e "Valid OPTION values:"
  # build the list of options, sorting them
  {
    echo -e "  -m   Use monochrome output, coloured output is used by default."
    echo -e "  -h   Display this help"
    if [ -n "${specific_options}" ]; then
      echo -e "${specific_options}"
    fi
  } | sort
}

show_default_services_usage() {
  show_default_usage "[SERVICE]..." "$@"
  show_services_usage_part
}

show_default_service_usage() {
  show_default_usage "[SERVICE]" "$@"
  show_services_usage_part
}

get_config_env_var() {
  local -r var_name="$1"
  # Use indirection to get value of the env var with this name
  local var_value="${!var_name}" 

  if [ -z "${var_value}" ]; then
    # Not set so try getting it from the yaml
    local -r yaml_file="${DIR}/config/${STACK_NAME}.yml"

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
  if grep -q "^${service_name}$" "${DIR}/${stack_services_file}"; then
    return 0;
  else
    return 1;
  fi
}

does_container_exist() {
  check_arg_count 1 "$@"
  local  service_name="$1"
  if is_service_in_stack "${service_name}"; then
    # first check if the service has a container or not
    if docker container inspect "${service_name}" 1>/dev/null 2>&1; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

is_container_running() {
  check_arg_count 1 "$@"
  local service_name="$1"
  if does_container_exist "${service_name}"; then
    # now check the run state of the container
    local -r state="$(docker inspect -f '{{.State.Running}}' "${service_name}")"
    if [ "${state}" == "true" ]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

# Return zero if any of the supplied services are in the stack
is_at_least_one_service_in_stack() {
  local -r service_names=( "$@" )
  local regex="^"
  for service_name in "${service_names[@]}"; do
    regex+="(${service_name})"
  done
  regex+="$"

  # return true if service_name is in the file
  # shellcheck disable=SC2151
  if grep -q "${regex}" "${DIR}/${stack_services_file}"; then
    return 0;
  else
    return 1;
  fi
}

check_container_health() {
  check_arg_count 1 "$@"
  local -r service_name="$1"
  local return_code=0

  echo
  echo -e "Checking the run state of container ${GREEN}${service_name}${NC}"

  if does_container_exist "${service_name}"; then
    if is_container_running "${service_name}"; then
      echo_running
      return_code=0
    else
      echo_stopped
      return_code=1
    fi
  else
    echo_doesnt_exist
    return_code=0
  fi

  return ${return_code}
}

check_service_health() {
  if [ $# -ne 4 ]; then
    echo -e "${RED}ERROR${NC}:" \
      "Invalid arguments. Usage: ${BLUE}health.sh HOST PORT PATH${NC},\n" \
      "e.g. health.sh localhost 8080 stroomAdmin\n" \
      "Arguments [$*]" >&2
    dump_call_stack
    exit 1
  fi

  local -r health_check_service="$1"
  local -r health_check_host="$2"
  local -r health_check_port="$3"
  local -r health_check_path="$4"

  local -r health_check_url="http://${health_check_host}:${health_check_port}/${health_check_path}/healthcheck"
  local -r health_check_pretty_url="${health_check_url}?pretty=true"
  local return_code=0

  echo
  echo -e "Checking the health of ${GREEN}${health_check_service}${NC}" \
    "using ${BLUE}${health_check_pretty_url}${NC}"

  local -r http_status_code=$( \
    curl \
      -s \
      -o /dev/null \
      -w "%{http_code}" \
      "${health_check_url}"\
  )
  #echo "http_status_code: $http_status_code"

  # First hit the url to see if it is there
  if [ "x501" = "x${http_status_code}" ]; then
    # Server is up but no healthchecks are implmented, so assume healthy
    echo_healthy
  elif [ "x200" = "x${http_status_code}" ] \
    || [ "x500" = "x${http_status_code}" ]; then

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

        return_code="${unhealthy_count}"
      fi
    else
      # non-jq approach
      if [ "x200" = "x${http_status_code}" ]; then
        echo_healthy
      elif [ "x500" = "x${http_status_code}" ]; then
        echo_unhealthy
        echo -e "See ${BLUE}${health_check_pretty_url}${NC} for details"
        # Don't know how many are unhealthy but it is at least one
        return_code=1
      fi
    fi
  else
    echo_unhealthy
    local err_msg
    err_msg="$(curl -s --show-error "${health_check_url}" 2>&1)"
    echo -e "${RED}${err_msg}${NC}"
    return_code=1
  fi
  return ${return_code}
}

check_service_health_if_in_stack() {
  local -r service_name="$1"
  local -r host="$2"
  local -r admin_port_var_name="$3"
  local -r admin_path="$4"
  local unhealthy_count=0

  if is_service_in_stack "${service_name}" \
    && is_container_running "${service_name}"; then

    local admin_port
    admin_port="$(get_config_env_var "${admin_port_var_name}")"


    total_unhealthy_count=$((total_unhealthy_count + unhealthy_count))

    if [ "${unhealthy_count}" -eq 0 ]; then
      check_service_health \
        "${service_name}" \
        "${host}" \
        "${admin_port}" \
        "${admin_path}" || unhealthy_count=$?
    fi

    total_unhealthy_count=$((total_unhealthy_count + unhealthy_count))
  fi
}

check_containers() {
  local unhealthy_count=0

  local service_name
  while read -r service_name; do
    # OR to stop set -e exiting the script
    check_container_health "${service_name}" || unhealthy_count=$?

    total_unhealthy_count=$((total_unhealthy_count + unhealthy_count))
    #((total_unhealthy_count+=unhealthy_count))
  done < "${DIR}/${stack_services_file}"
}

check_overall_health() {

  local -r host="localhost"
  local total_unhealthy_count=0

  check_containers

  echo

  if command -v jq 1>/dev/null; then 
    # jq is available so do a more complex health check
    local is_jq_installed=true
  else
    # jq is not available so do a simple health check
    echo -e "\n${YELLOW}Warning${NC}: Doing simple health check as ${BLUE}jq${NC} is not installed."
    echo -e "See ${BLUE}https://stedolan.github.io/jq/${NC} for details on how to install it."
    local is_jq_installed=false
  fi 

  check_service_health_if_in_stack \
    "stroom" \
    "${host}" \
    "STROOM_ADMIN_PORT" \
    "stroomAdmin"

  check_service_health_if_in_stack \
    "stroom-proxy-remote" \
    "${host}" \
    "STROOM_PROXY_REMOTE_ADMIN_PORT" \
    "proxyAdmin"

  check_service_health_if_in_stack \
    "stroom-proxy-local" \
    "${host}" \
    "STROOM_PROXY_LOCAL_ADMIN_PORT" \
    "proxyAdmin"

  check_service_health_if_in_stack \
    "stroom-auth-service" \
    "${host}" \
    "STROOM_AUTH_SERVICE_ADMIN_PORT" \
    "authenticationServiceAdmin"

  check_service_health_if_in_stack \
    "stroom-stats" \
    "${host}" \
    "STROOM_STATS_ADMIN_PORT" \
    "statsAdmin"

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

  if is_at_least_one_service_in_stack "${SERVICES_WITH_HEALTH_CHECK[@]}"; then

    echo
    echo -e "The following admin pages are available"
    echo
    local admin_port
    if is_service_in_stack "stroom"; then
      admin_port="$(get_config_env_var "STROOM_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom" "http://localhost:${admin_port}/stroomAdmin"
    fi
    if is_service_in_stack "stroom-stats"; then
      admin_port="$(get_config_env_var "STROOM_STATS_SERVICE_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Stats" "http://localhost:${admin_port}/statsAdmin"
    fi
    if is_service_in_stack "stroom-proxy-local"; then
      admin_port="$(get_config_env_var "STROOM_PROXY_LOCAL_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Proxy (local)" "http://localhost:${admin_port}/proxyAdmin"
    fi
    if is_service_in_stack "stroom-proxy-remote"; then
      admin_port="$(get_config_env_var "STROOM_PROXY_REMOTE_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Proxy (remote)" "http://localhost:${admin_port}/proxyAdmin"
    fi
    if is_service_in_stack "stroom-auth-service"; then
      admin_port="$(get_config_env_var "STROOM_AUTH_SERVICE_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Auth" "http://localhost:${admin_port}/authenticationServiceAdmin"
    fi
  fi

  if is_at_least_one_service_in_stack "stroom" "stroom-proxy-local" "stroom-proxy-remote"; then
    echo
    echo -e "Data can be POSTed to Stroom using the following URLs (see README for details)"
    echo
    if is_service_in_stack "stroom"; then
      echo_info_line "${padding}" "Stroom (direct)" "https://localhost/stroom/datafeed"
    fi
    if is_service_in_stack "stroom-proxy-local"; then
      echo_info_line "${padding}" "Stroom Proxy (local)" "https://localhost:${STROOM_PROXY_LOCAL_HTTPS_APP_PORT}/stroom/datafeed"
    fi
    if is_service_in_stack "stroom-proxy-remote"; then
      echo_info_line "${padding}" "Stroom Proxy (remote)" "https://localhost:${STROOM_PROXY_REMOTE_HTTPS_APP_PORT}/stroom/datafeed"
    fi

    if is_service_in_stack "stroom"; then
      echo
      echo -e "The Stroom user interface can be accessed at the following URL"
      echo
      echo_info_line "${padding}" "Stroom UI" "https://localhost/stroom"
      echo
      echo -e "  (Login with the default username/password: ${BLUE}admin${NC}/${BLUE}admin${NC})"
      echo
    fi

  fi
}

start_stack() {
  # These lines may help in debugging the config that is passed to the containers
  #env
  #docker-compose -f "$DIR"/config/"${STACK_NAME}".yml config

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
    --project-name "${STACK_NAME}" \
    -f "$DIR/config/${STACK_NAME}.yml" \
    up \
    -d \
    "${@}"
}

stop_services_if_in_stack() {
  check_arg_count_at_least 1 "$@"
  local -r service_names_to_shutdown=( "$@" )

  # loop over all services in gracefull shutdown order and if it is one
  # of the requested servcies, shut it down.
  for service_name_to_shutdown in "${SERVICE_SHUTDOWN_ORDER[@]}"; do
    if element_in "${service_name_to_shutdown}" "${service_names_to_shutdown[@]}"; then
      stop_service_if_in_stack "${service_name_to_shutdown}"
    fi
  done
}


stop_service_if_in_stack() {
  check_arg_count 1 "$@"
  local -r service_name="$1"

  if is_service_in_stack "${service_name}"; then
    echo -e "${GREEN}Stopping container ${BLUE}${service_name}${NC}"
    # first check if the service has a container or not
    if docker container inspect "${service_name}" 1>/dev/null 2>&1; then

      # now check the run state of the container
      local -r state="$(docker inspect -f '{{.State.Running}}' "${service_name}")"

      if [ "${state}" = "true" ]; then
        # shellcheck disable=SC2094
        docker-compose \
          --project-name "${STACK_NAME}" \
          -f "$DIR"/config/"${STACK_NAME}".yml \
          stop \
          "${service_name}"
      else
        echo -e "Container ${BLUE}${service_name}${NC} is not running"
      fi
    else
      echo -e "Container ${BLUE}${service_name}${NC} does not exist"
    fi
  fi
}

stop_stack() {
  echo -e "${GREEN}Stopping the docker containers in graceful order${NC}"
  echo

  local all_services=()
  while read -r service_to_stop; do
    all_services+=( "${service_to_stop}" )
  done < "${DIR}/${stack_services_file}"

  stop_services_if_in_stack "${all_services[@]}"

  # In case we have missed any stop the whole project
  echo -e "${GREEN}Stopping any remaining containers in the stack${NC}"
  # shellcheck disable=SC2094
  docker-compose \
    --project-name "${STACK_NAME}" \
    -f "$DIR/config/${STACK_NAME}.yml" \
    stop
}

wait_for_stroom() {
  echo
  echo -e "${GREEN}Waiting for Stroom to complete its start up.${NC}"
  echo -e "${DGREY}Stroom has to build its database tables when started for the first time,${NC}"
  echo -e "${DGREY}so this may take a minute or so. Subsequent starts will be quicker.${NC}"

  local admin_port
  admin_port="$(get_config_env_var "STROOM_ADMIN_PORT")"

  wait_for_200_response "http://localhost:${admin_port}/stroomAdmin"
}

wait_for_stroom_auth_service() {
  echo
  echo -e "${GREEN}Waiting for Stroom Authentication to complete its start up.${NC}"

  local admin_port
  admin_port="$(get_config_env_var "STROOM_AUTH_SERVICE_ADMIN_PORT")"

  wait_for_200_response "http://localhost:${admin_port}/authenticationServiceAdmin"
}

wait_for_stroom_stats() {
  echo
  echo -e "${GREEN}Waiting for Stroom Stats to complete its start up.${NC}"

  local admin_port
  admin_port="$(get_config_env_var "STROOM_STATS_SERVICE_ADMIN_PORT")"

  wait_for_200_response "http://localhost:${admin_port}/statsAdmin"
}

wait_for_stroom_proxy_local() {
  echo
  echo -e "${GREEN}Waiting for Stroom Proxy (local) to complete its start up.${NC}"
  echo -e "${DGREY}Stroom Proxy has to build its database tables when started for the first time,${NC}"
  echo -e "${DGREY}so this may take a minute or so. Subsequent starts will be quicker.${NC}"

  local admin_port
  admin_port="$(get_config_env_var "STROOM_PROXY_LOCAL_ADMIN_PORT")"

  wait_for_200_response "http://localhost:${admin_port}/proxyAdmin"
}

wait_for_stroom_proxy_remote() {
  echo
  echo -e "${GREEN}Waiting for Stroom Proxy (remote) to complete its start up.${NC}"
  echo -e "${DGREY}Stroom Proxy has to build its database tables when started for the first time,${NC}"
  echo -e "${DGREY}so this may take a minute or so. Subsequent starts will be quicker.${NC}"

  local admin_port
  admin_port="$(get_config_env_var "STROOM_PROXY_REMOTE_ADMIN_PORT")"

  wait_for_200_response "http://localhost:${admin_port}/proxyAdmin"
}

wait_for_service_to_start() {
  # We don't know which services are in the stack or have been started so
  # wait one one service in this order of precidence, checking each one is
  # actually running first. They should be in order of the startup speed,
  # slowest first
  if is_container_running "stroom"; then
    wait_for_stroom
  elif is_container_running "stroom-proxy-local"; then
    wait_for_stroom_proxy_local
  elif is_container_running "stroom-proxy-remote"; then
    wait_for_stroom_proxy_remote
  elif is_container_running "stroom-auth-service"; then
    wait_for_stroom_auth_service
  elif is_container_running "stroom-stats"; then
    wait_for_stroom_stats
  fi
  # If we fall out here then we have nothing useful to wait for
}

