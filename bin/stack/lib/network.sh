#!/usr/bin/env bash
#
# Re-usable network functions

determineHostAddress() {
    if [ "$(uname)" == "Darwin" ]; then
        # Code required to find IP address is different in MacOS
        ip=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}')
    else
        ip=$(ip route get 1 |awk 'match($0,"src [0-9\\.]+") {print substr($0,RSTART+4,RLENGTH-4)}')
    fi
    echo
    echo -e "Using IP ${GREEN}${ip}${NC} as the advertised host, as determined from the operating system"

    if [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo
        echo -e "${RED}ERROR${NC} IP address [${GREEN}${ip}${NC}] is not valid, try setting '${BLUE}STROOM_RESOURCES_ADVERTISED_HOST=x.x.x.x${NC}' in ${BLUE}local.env${NC}" >&2
        exit 1
    fi

    echo "${ip}"
}