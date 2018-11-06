#!/usr/bin/env bash
#
# Checks the health of each app using the supplied admin url

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh

setup_echo_colours

echo_healthy() {
    echo -e "  Status:   ${GREEN}HEALTHY${NC}"
}

echo_unhealthy() {
    echo -e "  Status:   ${RED}UNHEALTHY${NC}"
    echo -e "  Details:"
    echo
}

check_health() {
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

    local -r http_status_code=$(curl -s -o /dev/null -w "%{http_code}" ${health_check_url})
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
                curl -s ${health_check_url} | 
                jq '[to_entries[] | {key: .key, value: .value.healthy}] | map(select(.value == false)) | length')

            #echo "unhealthy_count: $unhealthy_count"
            if [ ${unhealthy_count} -eq 0 ]; then
                echo_healthy
            else
                echo_unhealthy

                # Dump details of the failing health checks
                curl -s ${health_check_url} | 
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
        local err_msg=$(curl -s --show-error ${health_check_url} 2>&1)
        echo -e "${RED}${err_msg}${NC}"
        total_unhealthy_count=$((total_unhealthy_count + 1))
    fi
}

main() {
    # Read the file containing all the env var exports so we can test
    # if certain port variables are set or not
    source "$DIR"/config/<STACK_NAME>.env

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

    check_health "stroom" ${host} ${STROOM_ADMIN_PORT} "stroomAdmin"
    check_health "stroom-proxy" ${host} ${STROOM_PROXY_ADMIN_PORT} "proxyAdmin"
    check_health "stroom-auth-service" ${host} ${STROOM_AUTH_SERVICE_ADMIN_PORT} "authenticationServiceAdmin"
    if [[ ! -z ${STROOM_STATS_SERVICE_ADMIN_PORT} ]]; then
        check_health "stroom-stats" ${host} ${STROOM_STATS_SERVICE_ADMIN_PORT} "statsAdmin"
    fi

    echo
    if [ ${total_unhealthy_count} -eq 0 ]; then
        echo -e "Overall system health: ${GREEN}HEALTHY${NC}"
    else
        echo -e "Overall system health: ${RED}UNHEALTHY${NC}"
    fi

    return ${total_unhealthy_count}
}

main 

# return the unhealthy count so this script can be used in an automated way
exit $?
