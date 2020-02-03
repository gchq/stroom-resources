#!/bin/bash

# Script for downloading all the artifacts and docker images associated with
# a stroom stack release

set -e

BLACK_LISTED_TAGS=(
  "gchq/stroom-zookeeper:"
  "gchq/stroom-stats:"
  "gchq/stroom-stats-hbase:"
  "wurstmeister/kafka:"
  "sequenceiq/hadoop-docker:"
)

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

is_tag_blacklisted() {
  local tag_under_test="$1"; shift
  for black_listed_prefix in "${BLACK_LISTED_TAGS[@]}"; do
    if [[ "${tag_under_test}" =~ ${black_listed_prefix} ]]; then
      return 0
    fi
  done
  return 1
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

  info "Pulling docker image ${YELLOW}${tag}${GREEN}"
  docker pull "${tag}"
  info "Saving docker image ${YELLOW}${tag}${GREEN} to file ${BLUE}${name}"
  docker save -o "./${name}" "${tag}"
}

main() {
  setup_echo_colours

  if [ "$#" -ne 2 ]; then
    error "Invalid arguments"
    info "Usage: ${BLUE}$0 stack_version output_file"
    info "E.g:   ${BLUE}$0 v6.0-beta.34-3 /tmp/artifacts.tag.gz"
    exit 1
  fi

  local stack_version="$1"; shift
  local output_file="$1"; shift

  if [ -f "${output_file}" ]; then
    error "Output file ${BLUE}${output_file}${GREEN} already exists"
    exit 1
  fi

  local download_dir
  download_dir="$(mktemp -d -t "stroom_artifacts_XXXXXX")"
  info "Creating directory ${BLUE}${download_dir}"

  pushd "${download_dir}" > /dev/null

  setup_urls

  # Get all the github binary files
  download_binary_and_hash "${CORE_STACK_BINARY_URL}"
  download_binary_and_hash "${SERVICES_STACK_BINARY_URL}"
  download_binary_and_hash "${DBS_STACK_BINARY_URL}"

  # Use GH api to get the commit hash for our release tag
  local gh_api_refs_url="https://api.github.com/repos/gchq/stroom-resources/git/refs/tags/stroom-stacks-${stack_version}"

  info "Getting commit hash from ${BLUE}${gh_api_refs_url}"

  local gh_api_tags_url
  gh_api_tags_url="$( \
    curl -s "${gh_api_refs_url}" \
      | jq -r '.object.url' \
  )"
  
  # Use GH api to get the commit msg for our release commit and extract the
  # image tags from it
  info "Getting image tags from ${BLUE}${gh_api_refs_url}"
  local all_image_tags
  all_image_tags="$( \
    curl -s "$gh_api_tags_url" \
      | jq -r '.message' \
      | grep ":" \
      | sort \
      | uniq \
  )"

  info "Found the following image tags for release ${YELLOW}stroom-stacks-${stack_version}:"
  while read -r tag; do
    echo -e "  ${YELLOW}${tag}${NC}"
  done <<< "${all_image_tags}"

  while read -r tag; do
    if is_tag_blacklisted "${tag}"; then
      info "Tag ${YELLOW}${tag}${GREEN} is blacklisted so will be ignored"
    else
      download_image "${tag}"
    fi
  done <<< "${all_image_tags}"

  info "Creating archive ${BLUE}${output_file}"
  tar -cvf "${output_file}" ./*

  popd > /dev/null

  info "Deleting directory ${BLUE}${download_dir}"
  rm -rf "${download_dir}"
}

main "$@"
