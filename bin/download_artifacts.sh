#!/bin/bash

# Script for downloading all the artifacts and docker images associated with
# a stroom stack release

set -e

setup_urls() {
  STROOM_RELEASE_BASE="https://github.com/gchq/stroom/releases/download"
  STROOM_BINARY_URL="${STROOM_RELEASE_BASE}/${STROOM_TAG}/stroom-app-${STROOM_TAG}.zip"

  STROOM_RESOURCES_RELEASE_BASE="https://github.com/gchq/stroom-resources/releases/download"
  STACK_BASE="${STROOM_RESOURCES_RELEASE_BASE}/stroom-stacks-"
  CORE_STACK_BINARY_URL="${STACK_BASE}${stack_version}/stroom_core-${stack_version}.tar.gz"
  SERVICES_STACK_BINARY_URL="${STACK_BASE}${stack_version}/stroom_services-${stack_version}.tar.gz"
  DBS_STACK_BINARY_URL="${STACK_BASE}${stack_version}/stroom_dbs-${stack_version}.tar.gz"

  DOCKER_NAMESPACE="gchq"
}

setup_echo_colours() {
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

info() {
  echo -e "${GREEN}$*${NC}"
}

error() {
  echo -e "${RED}ERROR${GREEN}: $*${NC}"
}

download_binary_and_hash() {
  local url="$1"
  local hash_url="${url}.sha256"
  info "Downloading ${BLUE}${url}"
  wget -q "${url}"
  info "Downloading ${BLUE}${hash_url}"
  wget -q "${hash_url}"
}

download_gchq_image() {
  local partial_tag="$1"; shift
  local tag="${DOCKER_NAMESPACE}/${partial_tag}"
  download_image "${tag}"
}

download_image() {
  local tag="$1"; shift
  local name="${tag//\//_}.img"

  info "Pulling docker image ${BLUE}${tag}${GREEN} to file ${BLUE}${name}"
  docker pull "${tag}"
  docker save -o "./${name}" "${tag}"
}

main() {
  setup_echo_colours

  if [ "$#" -ne 3 ]; then
    error "Invalid arguments"
    info "Usage: ${BLUE}$0 output_file stack_version container_versions_file"
    info "E.g:   ${BLUE}$0 /tmp/artifacts.tag.gz v6.0-beta.34-3 ./stacks/container_versions.env"
    exit 1
  fi

  local output_file="$1"; shift
  local stack_version="$1"; shift
  local container_versions_file="$1"; shift

  if [ -f "${output_file}" ]; then
    error "Output file ${output_file} already exists"
    exit 1
  fi

  if [ ! -f "${container_versions_file}" ]; then
    error "container_versions file ${container_versions_file} doesn't exist"
    exit 1
  fi

  local download_dir
  download_dir="$(mktemp -d -t "stroom_artifacts_XXXXXX")"
  info "Creating directory ${BLUE}${download_dir}"

  # Source this so we get the docker image tag versions
  info "Sourcing ${BLUE}${container_versions_file}"
  # shellcheck disable=SC1090
  source "${container_versions_file}"

  pushd "${download_dir}" > /dev/null

  setup_urls

  download_binary_and_hash "${STROOM_BINARY_URL}"
  download_binary_and_hash "${CORE_STACK_BINARY_URL}"
  download_binary_and_hash "${SERVICES_STACK_BINARY_URL}"
  download_binary_and_hash "${DBS_STACK_BINARY_URL}"

  download_gchq_image "stroom:${STROOM_TAG}"
  download_gchq_image "stroom-proxy:${STROOM_PROXY_TAG}"
  download_gchq_image "stroom-nginx:${STROOM_NGINX_TAG}"
  download_gchq_image "stroom-auth-service:${STROOM_AUTH_SERVICE_TAG}"
  download_gchq_image "stroom-auth-ui:${STROOM_AUTH_UI_TAG}"
  download_gchq_image "stroom-log-sender:${STROOM_LOG_SENDER_TAG}"
  download_gchq_image "stroom-log-sender:${STROOM_LOG_SENDER_TAG}"

  # TODO need to get this tag version from somewhere
  download_image "mysql:5.6.43"

  info "Creating archive ${BLUE}${output_file}"
  tar -cvf "${output_file}" ./*

  popd > /dev/null

  info "Deleting directory ${BLUE}${download_dir}"
  rm -rf "${download_dir}"

}

main "$@"
