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

get_services_in_stack() {
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

get_all_images_in_stack() {
  # Grepping yaml is far from ideal, we could do with something like yq or
  # ruby + jq to parse it properly, but that means more prereqs.
  # However the yaml is output from docker-compose so is in a fairly
  # consistent format.
  docker-compose \
    --project-name "${STACK_NAME}" \
    -f "$DIR/config/${STACK_NAME}.yml" \
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
    done <<< "$( get_services_in_stack )"
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
  # return the value via stdout
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
  if get_services_in_stack | grep -qP "${regex}"; then
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
  debug_arguments "$@"
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
  debug "http_status_code: $http_status_code"

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

      debug "unhealthy_count: $unhealthy_count"
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
  #done <<< "$( cut -d "|" -f 1 < "${DIR}/${STACK_SERVICES_FILENAME}" )"
  done <<< "$( get_services_in_stack )"
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
    echo -e "\n${YELLOW}Warning${NC}: Doing simple health check as" \
      "${BLUE}jq${NC} is not installed."
    echo -e "See ${BLUE}https://stedolan.github.io/jq/${NC} for details on" \
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
  printf "  ${GREEN}%s${NC} %s${BLUE}${unpadded_string}${NC}\n" \
    "${padded_string}" "${padding:${#padded_string}}"
}

display_active_stack_services() {
  echo
  echo -e "Active stack services and image versions:"
  echo

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

  display_active_stack_services

  if is_at_least_one_service_in_stack "${SERVICES_WITH_HEALTH_CHECK[@]}"; then

    echo
    echo -e "The following admin pages are available"
    echo
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
    echo
    echo -e "Data can be POSTed to Stroom using the following URLs (see README for details)"
    echo
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

  echo -e "${GREEN}Creating and starting the docker containers and volumes${NC}"
  echo

  determing_docker_host_details

  local stack_services=()
  while read -r service_to_start; do
    stack_services+=( "${service_to_start}" )
  # TODO add cut into the mix here
  done <<< "$( get_services_in_stack )"

  # Explicitly set services to start so we can use the SERVICES file to
  # control what services run on the node.
  if [ "$#" -eq 0 ]; then
    services_to_start=( "${stack_services[@]}" )
  else
    services_to_start=( "${@}" )
  fi

  # shellcheck disable=SC2094
  docker-compose \
    --project-name "${STACK_NAME}" \
    -f "$DIR/config/${STACK_NAME}.yml" \
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

stop_stack_quickly() {
  echo -e "${GREEN}Stopping all the docker containers at once${NC}"
  echo

  docker-compose \
    --project-name "${STACK_NAME}" \
    -f "$DIR/config/${STACK_NAME}.yml" \
    stop "$@"
}

stop_stack_gracefully() {
  echo -e "${GREEN}Stopping the docker containers in graceful order${NC}"
  echo

  local all_services=()
  while read -r service_to_stop; do
    all_services+=( "${service_to_stop}" )
  done <<< "$( get_services_in_stack )"

  stop_services_if_in_stack "${all_services[@]}"

  # In case we have missed any stop the whole project
  echo -e "${GREEN}Stopping any remaining containers in the stack${NC}"
  docker-compose \
    --project-name "${STACK_NAME}" \
    -f "$DIR/config/${STACK_NAME}.yml" \
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

check_installed_version_at_least() {
  debug_arguments "$@"
  local default_version_regex="(?<=[\s,])\d+\.\d+\.\d+(?=[\s,])"
  check_arg_count_at_least 3 "$@"

  local cmd="$1"; shift
  local version_arg="$1"; shift
  local min_version="$1"; shift
  if [ "$#" -gt 0 ]; then
    local version_regex="$1"; shift
  else
    local version_regex="${default_version_regex}"
  fi

  if check_is_installed "${cmd}"; then
    local version_output
    version_output="$("${cmd}" "${version_arg}" | head -n1)"

    if [ -n "${version_output}" ]; then
      local installed_version
      installed_version="$( \
        grep -oP "${version_regex}" <<<"${version_output}" || true)" 

      if [ -n "${installed_version}" ]; then
        debug "min_version: [$min_version], installed_version: [$installed_version]"

        compare_versions "${cmd}" "${min_version}" "${installed_version}"
        local return_code="$?"
        error_count=$(( error_count + return_code ))
      else
        echo -e "${RED}Warn${NC}: Unable to determine installed" \
          "version of ${BLUE}${cmd}${NC}"
      fi
    else
      echo -e "${RED}Warn${NC}: Unable to determine installed" \
        "version of ${BLUE}${cmd}${NC}"
    fi
  fi
}

check_for_gnu_version() {
  debug_arguments "$@"
  check_arg_count 2 "$@"
  local cmd="$1"; shift
  local version_arg="$1"; shift

  if check_is_installed "${cmd}"; then
    local installed_version
    installed_version="$("${cmd}" "${version_arg}" | head -n1)"
    debug "installed_version: [$installed_version]"

    if [[ ! "${installed_version}" =~ \(GNU.*?\) ]]; then
      echo -e "  ${RED}Error${GREEN}:" \
        "${BLUE}${cmd}${GREEN} is installed but is not the GNU version${NC}"
      error_count=$(( error_count + 1 ))
    fi
  fi
}

check_bash_version_at_least() {
  debug_arguments "$@"
  local version_regex="\d+\.\d+\.\d"
  check_arg_count_at_least 1 "$@"

  local min_version="$1"; shift

  if check_is_installed "bash"; then
    local version_output
    version_output="${BASH_VERSION}"

    if [ -n "${version_output}" ]; then
      local installed_version
      installed_version="$( \
        grep -oP "${version_regex}" <<<"${version_output}" || true)" 

      if [ -n "${installed_version}" ]; then
        debug "min_version: [$min_version], installed_version: [$installed_version]"

        compare_versions "${cmd}" "${min_version}" "${installed_version}" \
          || error_count=$(( error_count + 1 ))
      else
        echo -e "${RED}Error${NC}: Unable to determine installed version of bash"
      fi
    else
      echo -e "${RED}Error${NC}: Unable to determine installed version of bash"
    fi
  fi
}

check_is_installed() {
  debug_arguments "$@"
  check_arg_count_at_least 1 "$@"
  local commands=( "${@}" )
  local was_found=false
  local cmds_text=""

  for cmd in "${commands[@]}"; do
    cmds_text="${cmds_text} or ${BLUE}${cmd}${NC}"
  done
  # strip trailing ' or '
  cmds_text="${cmds_text# or }"

  for cmd in "${commands[@]}"; do
    if command -v "${cmd}" > /dev/null; then
      debug "${cmd} is installed"
      was_found=true
      break
    fi
  done

  local return_code=0;
  if [ "${was_found}" = false ]; then
    echo -e "  ${RED}Error${GREEN}:" \
      "${BLUE}${cmds_text}${GREEN} is not installed${NC}"
    error_count=$(( error_count + 1 ))
    return_code=1
  fi
  return ${return_code}
}

compare_versions() {
  debug_arguments "$@"
  check_arg_count 3 "$@"
  local cmd="$1"; shift
  local expected_version="$1"; shift
  local actual_version="$1"; shift
  local whole_regex='[0-9]+\.[0-9]+\.[0-9]+'
  local return_code=0
  local is_verion_too_old=false

  if [ "${expected_version}" != "${actual_version}" ]; then
    # Not an exact match so see if we can parse the version number
    if [[ "${actual_version}" =~ ${whole_regex} ]]; then
      local major_regex='^[0-9]+'
      local minor_regex='(?<=\.)[0-9]+(?=\.)'
      local patch_regex='[0-9]+$'

      # $((10#$x)) is basically doing convert from base10 to base10 to
      # strip leading zeros
      local expected_major
      expected_major="$(grep -oP "${major_regex}" <<<"${expected_version}" )"
      expected_major=$((10#$expected_major))

      local actual_major
      actual_major="$(grep -oP "${major_regex}" <<<"${actual_version}" )"
      actual_major=$((10#$actual_major))

      debug "major [$expected_major] [$actual_major]"

      if [ "${actual_major}" -lt "${expected_major}" ]; then
        is_verion_too_old=true
      elif [ "${actual_major}" -eq "${expected_major}" ]; then
        # Now check minor as major matches
        local expected_minor
        expected_minor="$(grep -oP "${minor_regex}" <<<"${expected_version}" )"
        expected_minor=$((10#$expected_minor))
        local actual_minor
        actual_minor="$(grep -oP "${minor_regex}" <<<"${actual_version}" )"
        actual_minor=$((10#$actual_minor))
        debug "minor [$expected_minor] [$actual_minor]"

        if [ "${actual_minor}" -lt "${expected_minor}" ]; then
          is_verion_too_old=true
        elif [ "${actual_minor}" -eq "${expected_minor}" ]; then
          # Now check patch as minor matches
          local expected_patch
          expected_patch="$(grep -oP "${patch_regex}" <<<"${expected_version}" )"
          expected_patch=$((10#$expected_patch))
          local actual_patch
          actual_patch="$(grep -oP "${patch_regex}" <<<"${actual_version}" )"
          actual_patch=$((10#$actual_patch))
          debug "patch [$expected_patch] [$actual_patch]"

          if [ "${actual_patch}" -lt "${expected_patch}" ]; then
            is_verion_too_old=true
          fi
        fi
      fi
    else
      # Not a version number we recognise, so it may be ok, but we don't know
      is_verion_too_old=true
    fi

    if [ "${is_verion_too_old}" = true ]; then
      return_code=1
      echo -e "  ${RED}Error${GREEN}:" \
        "${BLUE}${cmd}${GREEN} version ${BLUE}${actual_version}${GREEN}" \
        "is installed, expecting at least ${BLUE}${expected_version}${NC}"
    fi
  fi
  return "${return_code}"
}

# Function taken from https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
vercomp() {
    if [[ "$1" == "$2" ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

check_prerequisites() {
  local error_count=0
  echo -e "Checking prerequisites"

  # BSD sed/grep as used on fruit based devices differs in behaviour
  # from GNU sed/grep
  # need to check for grep first as we use grep in some checks
  check_for_gnu_version "grep" "-V"
  check_for_gnu_version "sed" "--version"

  check_bash_version_at_least "4.0.0"

  # The version numbers mentioned here are mostly governed by the docker
  # compose syntax version that we use in the yml files, currently 2.4, see
  # https://docs.docker.com/compose/compose-file/compose-versioning/
  check_installed_version_at_least "xxx" "--version" "17.12.0"
  check_installed_version_at_least "docker" "--version" "37.12.0"
  check_installed_version_at_least "docker" "--version" "17.12.0"
  check_installed_version_at_least "docker-compose" "--version" "1.21.0"

  # Function returns 0/1 so need to OR with true to stop it triggering the
  # ERR trap
  check_is_installed "ksjdksdjskd" || true
  check_is_installed "awk" || true
  check_is_installed "basename" || true
  check_is_installed "curl" || true
  check_is_installed "cut" || true
  check_is_installed "gzip" || true
  check_is_installed "jq" || true

  if [ "$(uname)" == "Darwin" ]; then
    # Fruit based devices only
    check_is_installed "ifconfig" || true
  else
    check_is_installed "ip" || true
  fi

  if [ "${error_count}" -gt 0 ]; then
    echo -e "Failed ${error_count} prerequisite(s)"
  fi
  return ${error_count}
}
