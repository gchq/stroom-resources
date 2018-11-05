#!/usr/bin/env bash
#
# Run ctop, top for docker containers. 
#
# ctop keybindings are as follows
#   <enter>   Open container menu
#   a         Toggle display of all (running and non-running) containers
#   f	        Filter displayed containers (esc to clear when open)
#   H	        Toggle ctop header
#   h	        Open help dialog
#   s	        Select container sort field
#   r	        Reverse container sort order
#   o	        Open single view
#   l	        View container logs (t to toggle timestamp when open)
#   S	        Save current configuration to file
#   q	        Quit ctop

set -e

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#readonly HOST_IP=$(determine_host_address)

# Read the file containing all the env var exports to make them
# available to docker-compose
source "$DIR"/config/<STACK_NAME>.env

# The env vars are defined in ./config/*.env
# See create_stack_env.sh for how they get into the .env file in the stack build
docker run \
    -ti \
    --name ctop \
    --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    ${CTOP_DOCKER_REPO:-quay.io/vektorlab/ctop}:${CTOP_TAG:-latest}
