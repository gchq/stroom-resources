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

setup_echo_colours

# Only echo to stdout if we are not in QUIET_MODE
do_echo() {
  if [ "${QUIET_MODE}" = false ]; then
    echo -e "$@"
  fi
}

echo_running() {
  if [ "${QUIET_MODE}" = false ]; then
    echo -e "  Status:   ${GREEN}RUNNING${NC}"
  fi
}

echo_stopped() {
  if [ "${QUIET_MODE}" = false ]; then
    echo -e "  Status:   ${RED}STOPPED${NC}"
  fi
}

echo_doesnt_exist() {
  if [ "${QUIET_MODE}" = false ]; then
    echo -e "  Status:   ${RED}NO CONTAINER${NC}"
  fi
}

echo_healthy() {
  if [ "${QUIET_MODE}" = false ]; then
    echo -e "  Status:   ${GREEN}HEALTHY${NC}"
  fi
}

echo_unhealthy() {
  if [ "${QUIET_MODE}" = false ]; then
    echo -e "  Status:   ${RED}UNHEALTHY${NC}"
    echo -e "  Details:\n"
  fi
}

get_active_services_in_stack() {
  cut -d "|" -f 1 < "${DIR}/${STACK_SERVICES_FILENAME}" 
}

get_active_images_in_stack() {
  # Loop over all images in the stack then output the ones whose
  # non-namepsaced part is in the STACK_SERVICES_FILENAME file.
  while read -r image; do
    non_namespaced_tag="${image#*/}"
    #echo "checking image $image $non_namespaced_tag"
    # Make sure the non namespaced part, e.g.stroom-proxy:v6.0.18 
    # is in the list of active services
    if grep -qF "${non_namespaced_tag}" "${STACK_SERVICES_FILENAME}"; then
      echo "${image}"
    fi
  done <<< "$( get_all_images_in_stack )"
}

run_docker_compose_cmd() {
  extra_args=( "$@" )

  compose_file_args=()
  for yaml_file in "${DIR}"/config/*.yml; do
    compose_file_args+=( "-f" "${yaml_file}" )
  done

  docker-compose \
    --project-name "${STACK_NAME}" \
    "${compose_file_args[@]}" \
    "${extra_args[@]}"
}

get_all_images_in_stack() {
  # Grepping yaml is far from ideal, we could do with something like yq or
  # ruby + jq to parse it properly, but that means more prereqs.
  # However the yaml is output from docker-compose so is in a fairly
  # consistent format.
  run_docker_compose_cmd \
    config \
    | grep -P "^\s+image:.*$" \
    | grep -oP "(?<=image: ).*"
}

show_services_usage_part() {
  # shellcheck disable=SC2002
  if [ -f "${DIR}/${STACK_SERVICES_FILENAME}" ] \
    && [ "$(cat "${DIR}/${STACK_SERVICES_FILENAME}" | wc -l)" -gt 0 ]; then

    echo -e "Valid SERVICE values:"
    while read -r service; do
      echo -e "  ${service}"
    done <<< "$( get_active_services_in_stack )"
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

    local env_var_name_value
    env_var_name_value="$( \
      grep --no-filename -v "\w* echo " "${DIR}"/config/*.yml \
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
  # file is serviceName|fullyQualifiedDockerTag
  if grep -q "^${service_name}|" "${DIR}/${STACK_SERVICES_FILENAME}"; then
    return 0;
  else
    return 1;
  fi
}

validate_services() {
  for service_name in "$@"; do
    if ! is_service_in_stack "${service_name}"; then
      die "${RED}Error${NC}:" \
        "${BLUE}${service_name}${NC} is not part of this stack, use the -h argument to see the list of valid services"
    fi
  done
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
  local -r service_names_to_check=( "$@" )
  # trying to build a regex like "^(svc1|svc3|svc4)$"
  local regex="^("
  for service_name in "${service_names_to_check[@]}"; do
    regex+="${service_name}|"
  done
  regex="${regex%%|}}"
  regex+=")$"

  # return true if service_name is in the file
  # shellcheck disable=SC2151
  # TODO add cut into the mix here
  #if cut -d "|" -f 1 < "${DIR}/${STACK_SERVICES_FILENAME}" \
  if get_active_services_in_stack | grep -qP "${regex}"; then
    return 0;
  else
    return 1;
  fi
}

check_container_health() {
  check_arg_count 1 "$@"
  local -r service_name="$1"
  local return_code=0

  do_echo "\nChecking the run state of container ${GREEN}${service_name}${NC}"

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
    return_code=1
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

  do_echo "\nChecking the health of ${GREEN}${health_check_service}${NC}" \
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

      do_echo "\n  See ${BLUE}${health_check_url}?pretty=true${NC} for the full report"

        return_code="${unhealthy_count}"
      fi
    else
      # non-jq approach
      if [ "x200" = "x${http_status_code}" ]; then
        echo_healthy
      elif [ "x500" = "x${http_status_code}" ]; then
        echo_unhealthy
      do_echo "See ${BLUE}${health_check_pretty_url}${NC} for details"
        # Don't know how many are unhealthy but it is at least one
        return_code=1
      fi
    fi
  else
    echo_unhealthy
    local err_msg
    err_msg="$(curl -s --show-error "${health_check_url}" 2>&1)"
    do_echo "${RED}${err_msg}${NC}"
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
  #done <<< "$( cut -d "|" -f 1 < "${DIR}/${STACK_SERVICES_FILENAME}" )"
  done <<< "$( get_active_services_in_stack )"
}

check_overall_health() {

  local -r host="localhost"
  local total_unhealthy_count=0

  check_containers

  do_echo ""

  if command -v jq 1>/dev/null; then 
    # jq is available so do a more complex health check
    local is_jq_installed=true
  else
    # jq is not available so do a simple health check
    do_echo "\n${YELLOW}Warning${NC}: Doing simple health check as" \
      "${BLUE}jq${NC} is not installed."
    do_echo "See ${BLUE}https://stedolan.github.io/jq/${NC} for details on" \
      "how to install it."
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

  if [ "${total_unhealthy_count}" -eq 0 ]; then
    do_echo "\nOverall system health: ${GREEN}HEALTHY${NC}"
  else
    do_echo "\nOverall system health: ${RED}UNHEALTHY${NC}"
  fi

  return ${total_unhealthy_count}
}

echo_info_line() {
  # Echos a line like "  PADDED_STRING                    UNPADDED_STRING"

  local -r padding=$1
  local -r padded_string=$2
  local -r unpadded_string=$3
  # Uses bash substitution to only print the part of padding beyond the length of padded_string
  printf "  ${GREEN}%s${NC} %s${BLUE}${unpadded_string}${NC}\n" \
    "${padded_string}" "${padding:${#padded_string}}"
}

display_active_stack_services() {
  echo -e "\nActive stack services and image versions:\n"

  # Used for right padding 
  local -r padding="                            "

  while read -r line; do
    local service_name="${line%%|*}"
    local image_tag="${line#*|}"
    echo_info_line "${padding}" "${service_name}" "${image_tag}"
  done < "${DIR}/${STACK_SERVICES_FILENAME}"
}

display_stack_info() {
  # see if the terminal supports colors...
  no_of_colours=$(tput colors)

  if [ "${MONOCHROME}" = false ]; then
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

  display_active_stack_services

  if is_at_least_one_service_in_stack "${SERVICES_WITH_HEALTH_CHECK[@]}"; then

    echo -e "\nThe following admin pages are available\n"
    local admin_port
    if is_service_in_stack "stroom"; then
      admin_port="$(get_config_env_var "STROOM_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom" \
        "http://localhost:${admin_port}/stroomAdmin"
    fi
    if is_service_in_stack "stroom-stats"; then
      admin_port="$(get_config_env_var "STROOM_STATS_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Stats" \
        "http://localhost:${admin_port}/statsAdmin"
    fi
    if is_service_in_stack "stroom-proxy-local"; then
      admin_port="$(get_config_env_var "STROOM_PROXY_LOCAL_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Proxy (local)" \
        "http://localhost:${admin_port}/proxyAdmin"
    fi
    if is_service_in_stack "stroom-proxy-remote"; then
      admin_port="$(get_config_env_var "STROOM_PROXY_REMOTE_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Proxy (remote)" \
        "http://localhost:${admin_port}/proxyAdmin"
    fi
    if is_service_in_stack "stroom-auth-service"; then
      admin_port="$(get_config_env_var "STROOM_AUTH_SERVICE_ADMIN_PORT")"
      echo_info_line "${padding}" "Stroom Auth" \
        "http://localhost:${admin_port}/authenticationServiceAdmin"
    fi
  fi

  if is_at_least_one_service_in_stack "stroom" "stroom-proxy-local" "stroom-proxy-remote"; then
    echo -e "\nData can be POSTed to Stroom using the following URLs (see README for details)\n"
    if is_service_in_stack "stroom"; then
      echo_info_line "${padding}" "Stroom (direct)" "https://localhost/stroom/datafeeddirect"
    fi
    if is_service_in_stack "stroom-proxy-local"; then
      echo_info_line "${padding}" "Stroom Proxy (local)" \
        "https://localhost/stroom/datafeed"
    fi
    if is_service_in_stack "stroom-proxy-remote"; then
      local admin_port
      admin_port="$(get_config_env_var "STROOM_PROXY_REMOTE_APP_PORT")"
      echo_info_line "${padding}" "Stroom Proxy (remote)" \
        "http://localhost:${admin_port}/stroom/datafeed"
    fi

    if is_service_in_stack "stroom"; then
      echo -e "\nThe Stroom user interface can be accessed at the following URL\n"
      echo_info_line "${padding}" "Stroom UI" "https://localhost/stroom"
      echo -e "\n  (Login with the default username/password: ${BLUE}admin${NC}/${BLUE}admin${NC})\n"
    fi

  fi
}

determing_docker_host_details() {
  # If they haven't already been set in the env file, capture the hostname/ip
  # of the host running the containers so they can make it available to
  # stroom-log-sender. This is typically done by the file
  # add_container_identity_headers.sh in the container. They have to be
  # exported so docker-compose can use them.
  # shellcheck disable=SC2034
  export DOCKER_HOST_HOSTNAME="${DOCKER_HOST_HOSTNAME:-$(hostname --fqdn)}"
  # shellcheck disable=SC2034
  export DOCKER_HOST_IP="${DOCKER_HOST_IP:-$(determine_host_address)}"

  echo -e "${GREEN}Using hostname ${BLUE}${DOCKER_HOST_HOSTNAME}${GREEN} and" \
    "IP address ${BLUE}${DOCKER_HOST_IP}${GREEN} for audit logging.${NC}"
}

start_stack() {
  # These lines may help in debugging the config that is passed to the containers
  #env
  #docker-compose -f "$DIR"/config/"${STACK_NAME}".yml config

  echo -e "${GREEN}Creating and starting the docker containers and volumes${NC}\n"

  determing_docker_host_details

  local stack_services=()
  while read -r service_to_start; do
    stack_services+=( "${service_to_start}" )
  # TODO add cut into the mix here
  done <<< "$( get_active_services_in_stack )"

  # Explicitly set services to start so we can use the SERVICES file to
  # control what services run on the node.
  if [ "$#" -eq 0 ]; then
    services_to_start=( "${stack_services[@]}" )
  else
    services_to_start=( "${@}" )
  fi

  # shellcheck disable=SC2094
  run_docker_compose_cmd \
    up \
    -d \
    "${services_to_start[@]}"
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
        run_docker_compose_cmd \
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

stop_stack_quickly() {
  echo -e "${GREEN}Stopping all the docker containers at once${NC}\n"

  run_docker_compose_cmd \
    stop "$@"
}

stop_stack_gracefully() {
  echo -e "${GREEN}Stopping the docker containers in graceful order${NC}\n"

  local all_services=()
  while read -r service_to_stop; do
    all_services+=( "${service_to_stop}" )
  done <<< "$( get_active_services_in_stack )"

  stop_services_if_in_stack "${all_services[@]}"

  # In case we have missed any stop the whole project
  echo -e "${GREEN}Stopping any remaining containers in the stack${NC}"
  run_docker_compose_cmd \
    stop
}

wait_for_stroom() {

  local admin_port
  admin_port="$(get_config_env_var "STROOM_ADMIN_PORT")"
  local url="http://localhost:${admin_port}/stroomAdmin"
  local info_msg="Waiting for Stroom to complete its start up."
  local sub_info_msg=$'Stroom has to build its database tables when started for the first time,\nso this may take a minute or so. Subsequent starts will be quicker.'

  wait_for_200_response "${url}" "${info_msg}" "${sub_info_msg}"
}

wait_for_stroom_auth_service() {

  local admin_port
  admin_port="$(get_config_env_var "STROOM_AUTH_SERVICE_ADMIN_PORT")"
  local url="http://localhost:${admin_port}/authenticationServiceAdmin"
  local info_msg="Waiting for Stroom Authentication to complete its start up."

  wait_for_200_response "${url}" "${info_msg}"
}

wait_for_stroom_stats() {

  local admin_port
  admin_port="$(get_config_env_var "STROOM_STATS_SERVICE_ADMIN_PORT")"
  local url="http://localhost:${admin_port}/statsAdmin"
  local info_msg="Waiting for Stroom Stats to complete its start up."

  wait_for_200_response "${url}" "${info_msg}"
}

wait_for_stroom_proxy_local() {

  local admin_port
  admin_port="$(get_config_env_var "STROOM_PROXY_LOCAL_ADMIN_PORT")"
  local url="http://localhost:${admin_port}/proxyAdmin"
  local info_msg="Waiting for Stroom Proxy (local) to complete its start up."
  local sub_info_msg=$'Stroom Proxy has to build its database tables when started for the first time,\nso this may take a minute or so. Subsequent starts will be quicker.'

  wait_for_200_response "${url}" "${info_msg}" "${sub_info_msg}"
}

wait_for_stroom_proxy_remote() {

  local admin_port
  admin_port="$(get_config_env_var "STROOM_PROXY_REMOTE_ADMIN_PORT")"
  local url="http://localhost:${admin_port}/proxyAdmin"
  local info_msg="Waiting for Stroom Proxy (remote) to complete its start up."
  local sub_info_msg=$'Stroom Proxy has to build its database tables when started for the first time,\nso this may take a minute or so. Subsequent starts will be quicker.'

  wait_for_200_response "${url}" "${info_msg}" "${sub_info_msg}"
}

wait_for_service_to_start() {
  # We don't know which services are in the stack or have been started so
  # wait one one service in this order of precidence, checking each one is
  # actually running first. They should be in order of the startup speed,
  # slowest first
  if is_container_running "stroom"; then
    wait_for_stroom
  fi
  if is_container_running "stroom-proxy-local"; then
    wait_for_stroom_proxy_local
  fi
  if is_container_running "stroom-proxy-remote"; then
    wait_for_stroom_proxy_remote
  fi
  if is_container_running "stroom-auth-service"; then
    wait_for_stroom_auth_service
  fi
  if is_container_running "stroom-stats"; then
    wait_for_stroom_stats
  fi
  # If we fall out here then we have nothing useful to wait for
}

