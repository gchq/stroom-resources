#!/bin/bash
#
# Starts a single-box Stroom stack

# Accepts a PID and prints '.' until the pid goes away.
await_pid() {
  while [ -d /proc/$1 ]; do
    echo -n "."
    sleep 0.1s
  done
}

# Shell colour constants for use in 'echo -e'
setup_echo_colours() {
  RED='\033[1;31m'
  GREEN='\033[1;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[1;34m'
  LGREY='\e[37m'
  DGREY='\e[90m'
  NC='\033[0m' # No Color
}

welcome_user() {
  echo -e "${GREEN}Welcome to Stroom!"
  echo -e "${GREEN}------------------${NC}"
  echo -e "This script will run a single-box Stroom node. It needs to download some files into ${YELLOW}${HOME}/.stroom${NC}. It will also download some Docker images, which may take some time."

  read -p "Are you ready? [y/n]" -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      echo -e "Ok then. Bye!"
      exit 1
  fi
}

setup_resources() {
  mkdir -p ~/.stroom

  if [ -d "$RESOURCES_DIR" ]; then
    echo -e "${YELLOW}${RESOURCES_DIR}${NC} already exists. I'm going to make sure it's clean and up-to-date."
    cd "$RESOURCES_DIR"

    echo -en "Cleaning..."
    git clean -dfqx &
    await_pid $!

    echo -en "\nUpdating..."
    git pull &
    await_pid $!
  else 
    echo -e "Cloning ${YELLOW}${RESOURCES_REPO}${NC} into ${YELLOW}${RESOURCES_DIR}${NC}"

    git clone --quiet "${RESOURCES_REPO}" "$RESOURCES_DIR" &
    await_pid $!
  fi
}

run_stroom() {
  cd "${RESOURCES_DIR}/bin"
  ./bounceIt.sh -y
}

main() {
  # Exit the script on any error
  set -e

  # Set up constants
  readonly local RESOURCES_DIR="${HOME}/.stroom/quickStartResources"
  readonly local RESOURCES_REPO="git@github.com:gchq/stroom-resources.git"

  setup_echo_colours
  welcome_user
  setup_resources
  run_stroom
}

main "$@"