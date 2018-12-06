#!/bin/sh

main() {
    [ "$#" -eq 1 ] || (echo "'headers_file' argument not supplied!" && exit 1)
    headers_file="$1"

    # Write the details of the host of this container to the headers file 
    # for stroom-log-sender
    cat /dev/null > "${headers_file}"
    if [ ! -z "${DOCKER_HOST_HOSTNAME}" ]; then
        echo "OriginalHost:${DOCKER_HOST_HOSTNAME}" >> "${headers_file}"
    fi
    if [ ! -z "${DOCKER_HOST_IP}" ]; then
        echo "OriginalIP:${DOCKER_HOST_IP}" >> "${headers_file}"
    fi
    if [ ! -z "${GIT_TAG}" ]; then
        echo "OriginalImageGitTag:${GIT_TAG}" >> "${headers_file}"
    fi

    # This command works in alpine linux 3.8, but may be fragile and subject to change
    # with different docker versions.
    container_id="$(grep -o -e "docker/.*" /proc/self/cgroup | head -n 1 | sed "s/docker\/\(.*\)/\\1/")"
    if [ ! -z "${container_id}" ]; then
        echo "OriginalContainerId:${container_id}" >> "${headers_file}"
    fi

    echo "Dumping ${headers_file} contents:"
    echo "-------------------------------------------"
    cat "${headers_file}"
    echo "-------------------------------------------"
}

main "$@"
