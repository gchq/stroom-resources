#!/bin/bash

# exit script on any error
set -e

# shellcheck disable=SC1091
source travis.common.sh

do_release() {
  setup_colours
  dump_travis_env_vars

  # establish what version we are building
  if [ -n "$TRAVIS_TAG" ] && [[ "$TRAVIS_TAG" =~ ${RELEASE_VERSION_REGEX} ]] ; then

    # Tagged commit so use that as our build version, e.g. v6.0.0
  # shellcheck disable=SC2034
    BUILD_VERSION="$(echo "${TRAVIS_TAG}" | grep -oP "${VERSION_PART_REGEX}")"
    local -r tag_prefix="$(echo "${TRAVIS_TAG}" | grep -oP "${PREFIX_PART_REGEX}")"

    dump_build_vars
    echo -e "tag_prefix:                [${GREEN}${tag_prefix}${NC}]"

    if [[ ${TRAVIS_TAG} =~ ${TAG_PREFIX_STROOM_NGINX} ]]; then
      # This is a stroom-nginx release, so do a docker build/push
      echo -e "${GREEN}Performing a ${BLUE}stroom-nginx${GREEN} release to dockerhub${NC}"

      derive_docker_tags

      # build and release the image to dockerhub
      # shellcheck disable=SC2154
      release_to_docker_hub \
        "${DOCKER_REPO_STROOM_NGINX}" \
        "${DOCKER_CONTEXT_ROOT_STROOM_NGINX}" \
        "${allDockerTags[@]}"

    elif [[ ${TRAVIS_TAG} =~ ${TAG_PREFIX_STROOM_LOG_SENDER} ]]; then
      # This is a stroom-log-sender release, so do a docker build/push
      echo -e "${GREEN}Performing a ${BLUE}stroom-log-sender${GREEN} release to dockerhub${NC}"

      derive_docker_tags

      # build and release the image to dockerhub
      release_to_docker_hub \
        "${DOCKER_REPO_STROOM_LOG_SENDER}" \
        "${DOCKER_CONTEXT_ROOT_STROOM_LOG_SENDER}" \
        "${allDockerTags[@]}"

    elif [[ ${TRAVIS_TAG} =~ ${TAG_PREFIX_STROOM_ZOOKEEPER} ]]; then
      # This is a stroom-zookeeper release, so do a docker build/push
      echo -e "${GREEN}Performing a ${BLUE}stroom-zookeeper${GREEN} release to dockerhub${NC}"

      derive_docker_tags

      # build and release the image to dockerhub
      release_to_docker_hub \
        "${DOCKER_REPO_STROOM_ZOOKEEPER}" \
        "${DOCKER_CONTEXT_ROOT_STROOM_ZOOKEEPER}" \
        "${allDockerTags[@]}"

    elif element_in "${tag_prefix}" "${ALL_STACK_PREFIXES[@]}"; then
      # This is a stack release, so create the stack so travis deploy/releases
      # can pick it up
      echo -e "${GREEN}Performing a ${BLUE}${tag_prefix}${GREEN} stack release to github${NC}"

      do_versioned_stack_build "${tag_prefix}"

      # Only update the get_stroom script for a certain stack release
      if [ "${tag_prefix}" == "${GET_STROOM_STACK_NAME}" ]; then
        echo -e "${GREEN}Releasing a new get_stroom.sh script to GitHub pages for stack ${tag_prefix}${NC}"
        create_get_stroom_script
      fi
    fi
  else
    echo -e "${GREEN}Not a tagged commit (or a tag we recognise), nothing to release.${NC}"
  fi
}

# Start of script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main "$@"

exit 0
