#!/usr/bin/env bash

# This script aims to mimic the travis/github build on a local machine, with
# the exception of releasing artefacts to github and pushing to dockerhub.
# It does the following:
# - sets up various env vars that the build scripts expect
# - creates a build dir in /tmp
# - clones the stroom repo on your current branch into the build dir
# - runs the ci_build.sh script
#
# This script and the ci_build script run on this host but all parts
# of the build that need anything more than bash and standard shell tools
# are executed in docker containers.

set -eo pipefail

setup_echo_colours() {
  # Exit the script on any error
  set -e

  # shellcheck disable=SC2034
  if [ "${MONOCHROME}" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BLUE2=''
    DGREY=''
    NC='' # No Colour
  else 
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    BLUE2='\033[1;34m'
    DGREY='\e[90m'
    NC='\033[0m' # No Colour
  fi
}

debug_value() {
  local name="$1"; shift
  local value="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${name}: ${value}${NC}"
  fi
}

debug() {
  local str="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${str}${NC}"
  fi
}

main() {
  IS_DEBUG=false
  local runWithNonEmptyBuildDir
  if [[ "${1}" = "force" ]]; then
    runWithNonEmptyBuildDir=true
  else
    runWithNonEmptyBuildDir=false
  fi

  setup_echo_colours


  local clone_branch
  # get the current branch
  clone_branch="$(git rev-parse --abbrev-ref HEAD)"
  local repo_namespace="gchq"
  local repo_name="stroom-resources"

  # shellcheck disable=SC2034
  {
    # IMPORTANT - Stops us trying to push builds to dockerhub
    export LOCAL_BUILD=true

    export BUILD_BRANCH="${clone_branch}" # Needs to be a proper brach as we git clone this
    export BUILD_DIR="/tmp/${repo_name}_ci_build"
    export BUILD_COMMIT="dummy_commit_hash" # Uses in docker imagge
    export BUILD_IS_PULL_REQUEST="false" # ensures we do docker builds
    # To run with no tag use BUILD_TAG= ./travis.local_build.sh
    export BUILD_TAG="${BUILD_TAG=stroom-stacks-v9.9-dummy}" # Gets parsed and needs to be set to trigger aspects of the build
  }

  if [[ ! -n "${BUILD_TAG}" ]]; then
    echo -e "${YELLOW}WARNING:${NC} BUILD_TAG unset so won't run release" \
      "parts of build${NC}"
  fi

  if [[ -d "${BUILD_DIR}" ]]; then
    if [[ "${runWithNonEmptyBuildDir}" = true ]]; then
      echo -e "${YELLOW}WARNING:${NC} BUILD_DIR ${BLUE}${BUILD_DIR}${NC}" \
        "already exists, running anyway${NC}"
    else
      echo -e "${RED}ERROR:${NC} BUILD_DIR ${BLUE}${BUILD_DIR}${NC}" \
        "already exists, delete or use 'force' argument${NC}"
      exit 1
    fi
  fi

  mkdir -p "${BUILD_DIR}"

  # Make sure we start in the travis build dir
  pushd "${BUILD_DIR}" > /dev/null

  echo -e "${GREEN}Cloning branch ${BLUE}${clone_branch}${NC}" \
    "into ${BUILD_DIR}${NC}"

  # Clone stroom like travis would
  # Speed up clone with no depth and one branch
  git clone \
    --depth=1 \
    --branch "${clone_branch}" \
    --single-branch \
    "https://github.com/${repo_namespace}/${repo_name}.git" \
    "${BUILD_DIR}"

  echo -e "${GREEN}Running ${BLUE}ci_build.sh${NC}"
  ${BUILD_DIR}/ci_build.sh

  echo -e "${GREEN}Done local travis build${NC}"
}

main "$@"
