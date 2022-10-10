#!/usr/bin/env bash

function getContainerHealth {
  docker inspect --format "{{json .State.Health.Status }}" $1
}

function waitContainer {
  while STATUS=$(getContainerHealth $1); [ $STATUS != "\"healthy\"" ]; do
    if [ $STATUS == "\"unhealthy\"" ]; then
      echo "Failed!"
      exit -1
    fi
    printf .
    lf=$'\n'
    sleep 1
  done
  printf "$lf"
}

determineHostAddress() {
    # We need the IP to transpose into our config
    if [ "x${STROOM_RESOURCES_ADVERTISED_HOST}" != "x" ]; then
        ip="${STROOM_RESOURCES_ADVERTISED_HOST}"
        echo
        echo -e "Using IP ${GREEN}${ip}${NC} as the advertised host, as obtained from ${BLUE}STROOM_RESOURCES_ADVERTISED_HOST${NC}"
    else
        if [ "$(uname)" == "Darwin" ]; then
            # Code required to find IP address is different in MacOS
            ip=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}')
        else
            ip=$(ip route get 1 |awk 'match($0,"src [0-9\\.]+") {print substr($0,RSTART+4,RLENGTH-4)}')
        fi
        echo
        echo -e "Using IP ${GREEN}${ip}${NC} as the advertised host, as determined from the operating system"
    fi

    if [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo
        echo -e "${RED}ERROR${NC} IP address [${GREEN}${ip}${NC}] is not valid, try setting '${BLUE}STROOM_RESOURCES_ADVERTISED_HOST=x.x.x.x${NC}' in ${BLUE}local.env${NC}" >&2
        exit 1
    fi

    # This is used by the docker compose YML files, so they can tell a browser where to go
    export STROOM_RESOURCES_ADVERTISED_HOST="${ip}"
    echo
}
