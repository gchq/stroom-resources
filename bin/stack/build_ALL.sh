#!/usr/bin/env bash
#
# Builds all stacks at once

set -e

# shellcheck disable=SC1091
source lib/shell_utils.sh
setup_echo_colours

build_stack() {
  local stack_name="$1"
  local version="$2"

  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
  echo -e "${GREEN}Building stack ${BLUE}${stack_name}${NC}"

  local build_script="build_${stack_name}.sh"

  if [ ! -f "${build_script}" ]; then
    die "${RED}Error${NC}: Can't find stack build script ${BLUE}${build_script}${NC}"
  fi

  # Run the build script for the named stack
  # TODO If we have a services.txt file in stack_definitions then we could just
  # pass the stack name to build.sh and let it find the list of services
  # shellcheck disable=SC1090
  . "${build_script}" "${version}"

  echo -e "${GREEN}Finished building stack ${BLUE}${stack_name}${NC}"
  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
}

main() {
  local -r STACK_DEFINITIONS_DIR="stack_definitions"

  if [ ! -d "${STACK_DEFINITIONS_DIR}" ]; then
    die "${RED}Error${NC}: Can't find stack definitions directory ${BLUE}${STACK_DEFINITIONS_DIR}${NC}"
  fi

  local stack_names
  stack_names="$( \
    find  \
    ./${STACK_DEFINITIONS_DIR} \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -printf '%f\n'
  )"

  for stack_name in ${stack_names}; do
    build_stack "${stack_name}" "$@"
  done
}

main "$@"
