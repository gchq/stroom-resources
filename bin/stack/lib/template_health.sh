#!/usr/bin/env bash
#
# Checks the health of each app using the supplied admin url

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh

setup_echo_colours

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

    echo
    echo -e "Checking the health of ${GREEN}${health_check_service}${NC} using ${BLUE}${health_check_url}?pretty=true${NC}"

    local -r http_status_code=$(curl -s -o /dev/null -w "%{http_code}" ${health_check_url})

    #echo "http_status_code: $http_status_code"

    # First hit the url to see if it is there
    if [ "x501" = "x${http_status_code}" ]; then
        # Server is up but no healthchecks are implmented, so assume healthy
        echo -e "  Status: ${GREEN}HEALTHY${NC}"
    elif [ "x200" = "x${http_status_code}" ] || [ "x500" = "x${http_status_code}" ]; then
        # 500 code indicates at least one health check is unhealthy but jq will fish that out

        # Count all the unhealthy checks
        local -r unhealthy_count=$( \
            curl -s ${health_check_url} | 
            jq '[to_entries[] | {key: .key, value: .value.healthy}] | map(select(.value == false)) | length')

        #echo "unhealthy_count: $unhealthy_count"
        if [ ${unhealthy_count} -eq 0 ]; then
            echo -e "  Status: ${GREEN}HEALTHY${NC}"
        else
            echo -e "  Status: ${RED}UNHEALTHY${NC}"
            echo -e "  Details:"
            echo

            # Dump details of the failing health checks
            curl -s ${health_check_url} | 
                jq 'to_entries | map(select(.value.healthy == false)) | from_entries'

            echo
            echo -e "  See ${BLUE}${health_check_url}?pretty=true${NC} for the full report"

            total_unhealthy_count=$((total_unhealthy_count + unhealthy_count))
        fi
    else
        echo -e "  Status: ${RED}UNHEALTHY${NC}"
        local err_msg=$(curl -s --show-error ${health_check_url} 2>&1)
        echo -e "  Details:"
        echo
        echo -e "${RED}${err_msg}${NC}"
        total_unhealthy_count=$((total_unhealthy_count + 1))
    fi
}

main() {
    command -v jq 1>/dev/null || echo -e "\n${RED}ERROR: ${NC}The binary ${BLUE}jq${NC} is needed to run this script, see ${BLUE}https://stedolan.github.io/jq/${NC} for details on how to install it."

    # Read the file containing all the env var exports so we can test
    # if certain port variables are set or not
    source "$DIR"/config/<STACK_NAME>.env

    local -r host="localhost"
    local total_unhealthy_count=0

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
