#!/bin/bash

# exit script on any error
set -e

# shellcheck disable=SC2034
{
  # Prefixes for git tags that determine what the build does
  # Docker image prefixes
  TAG_PREFIX_STROOM_LOG_SENDER="stroom-log-sender"
  TAG_PREFIX_STROOM_NGINX="stroom-nginx"
  TAG_PREFIX_STROOM_ZOOKEEPER="stroom-zookeeper"
  # Stack prefixes
  TAG_PREFIX_STROOM_CORE="stroom_core"
  TAG_PREFIX_STROOM_CORE_TEST="stroom_core_test"
  TAG_PREFIX_STROOM_DBS="stroom_dbs"
  TAG_PREFIX_STROOM_FULL="stroom_full"
  TAG_PREFIX_STROOM_SERVICES="stroom_services"

  ALL_STACK_PREFIXES=(
    "${TAG_PREFIX_STROOM_CORE}"
    "${TAG_PREFIX_STROOM_CORE_TEST}"
    "${TAG_PREFIX_STROOM_DBS}"
    "${TAG_PREFIX_STROOM_FULL}"
    "${TAG_PREFIX_STROOM_SERVICES}"
  )

  DOCKER_REPO_STROOM_LOG_SENDER="gchq/stroom-log-sender"
  DOCKER_REPO_STROOM_NGINX="gchq/stroom-nginx"
  DOCKER_REPO_STROOM_ZOOKEEPER="gchq/stroom-zookeeper"

  DOCKER_CONTEXT_ROOT_STROOM_LOG_SENDER="stroom-log-sender/."
  DOCKER_CONTEXT_ROOT_STROOM_NGINX="stroom-nginx/."
  DOCKER_CONTEXT_ROOT_STROOM_ZOOKEEPER="dev-resources/images/zookeeper/."

  VERSION_FIXED_TAG=""
  SNAPSHOT_FLOATING_TAG=""
  MAJOR_VER_FLOATING_TAG=""
  MINOR_VER_FLOATING_TAG=""
  VERSION_PART_REGEX='v[0-9]+\.[0-9]+.*$'
  PREFIX_PART_REGEX="^[\\w-]+(?=-${VERSION_PART_REGEX})"
  RELEASE_VERSION_REGEX="^.*-${VERSION_PART_REGEX}"
  LATEST_SUFFIX="-LATEST"

  # The stack used for the get_stroom.sh script that we publish on gh-pages
  GET_STROOM_STACK_NAME="${TAG_PREFIX_STROOM_STROOM_CORE_TEST}"

  # The dir used to hold content for deploying to github pages, i.e.
  # https://gchq.github.io/stroom-resources
  GH_PAGES_DIR="${TRAVIS_BUILD_DIR}/gh-pages"
}

setup_colours() {
  # Shell Colour constants for use in 'echo -e'
  # e.g.  echo -e "My message ${GREEN}with just this text in green${NC}"
  # shellcheck disable=SC2034
  {
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    NC='\033[0m' # No Colour 
  }
}

# Returns 0 if $1 is in the array of elements passed as subsequent args
# e.g. 
# arr=( "one" "two" "three" )
# element_in "two" "${arr[@]}" # returns 0
element_in () {
  local element 
  local match="$1"
  shift
  for element; do 
    [[ "${element}" == "${match}" ]] && return 0
  done
  return 1
}

assert_all_containers_count() {
  local expected_count="$1"
  local actual_count
  expected_count="$(docker ps -a --format '{{.ID}}' | wc -l)"
  if [ "${actual_count}" -ne "${expected_count}" ]; then
    echo -e "${RED}Error${GREEN}:" \
      "Expecting ${BLUE}${expected_count}${GREEN} docker containers," \
      "found ${BLUE}${actual_count}${NC}"
    return 1
  else
    return 0
  fi
}

assert_running_containers_count() {
  local expected_count="$1"
  local actual_count
  expected_count="$(docker ps --format '{{.ID}}' | wc -l)"
  if [ "${actual_count}" -ne "${expected_count}" ]; then
    echo -e "${RED}Error${GREEN}:" \
      "Expecting ${BLUE}${expected_count}${GREEN} running docker containers," \
      "found ${BLUE}${actual_count}${NC}"
    return 1
  else
    return 0
  fi
}

# args: dockerRepo contextRoot tag1VersionPart tag2VersionPart ... tagNVersionPart
release_to_docker_hub() {
  # echo "releaseToDockerHub called with args [$@]"

  if [ $# -lt 3 ]; then
    echo "Incorrect args, expecting at least 3"
    exit 1
  fi
  dockerRepo="$1"
  contextRoot="$2"
  # shift the the args so we can loop round the open ended list of tags, $1 is
  # now the first tag
  shift 2

  allTagArgs=()

  for tagVersionPart in "$@"; do
    if [ "x${tagVersionPart}" != "x" ]; then
      # echo -e "Adding docker tag [${GREEN}${tagVersionPart}${NC}]"
      allTagArgs+=( "--tag=${dockerRepo}:${tagVersionPart}" )
    fi
  done

  echo -e "Building and releasing a docker image using:"
  echo -e "dockerRepo:                    [${GREEN}${dockerRepo}${NC}]"
  echo -e "contextRoot:                   [${GREEN}${contextRoot}${NC}]"
  echo -e "allTags:                       [${GREEN}${allTagArgs[*]}${NC}]"

  # If we have a TRAVIS_TAG (git tag) then use that, else use the floating tag
  docker build \
    "${allTagArgs[@]}" \
    --build-arg GIT_COMMIT="${TRAVIS_COMMIT}" \
    --build-arg GIT_TAG="${TRAVIS_TAG:-${SNAPSHOT_FLOATING_TAG}}" \
    "${contextRoot}"

  # The username and password are configured in the travis gui
  echo -e "Logging in to DockerHub"
  echo "$DOCKER_PASSWORD" | docker login \
    -u "$DOCKER_USERNAME" \
    --password-stdin \
    >/dev/null 2>&1 

  echo -e "Pushing the docker image to ${GREEN}${dockerRepo}${NC}" \
    "with tags: ${GREEN}${allTagArgs[*]}${NC}"
  docker push "${dockerRepo}" >/dev/null 2>&1

  echo -e "Logging out of Docker"
  docker logout >/dev/null 2>&1
}

derive_docker_tags() {
  # This is a tagged commit, so create a docker image with that tag
  VERSION_FIXED_TAG="${BUILD_VERSION}"

  # Extract the major version part for a floating tag
  majorVer=$(echo "${BUILD_VERSION}" | grep -oP "^v[0-9]+")
  if [ -n "${majorVer}" ]; then
    MAJOR_VER_FLOATING_TAG="${majorVer}${LATEST_SUFFIX}"
  fi

  # Extract the minor version part for a floating tag
  minorVer=$(echo "${BUILD_VERSION}" | grep -oP "^v[0-9]+\.[0-9]+")
  if [ -n "${minorVer}" ]; then
    MINOR_VER_FLOATING_TAG="${minorVer}${LATEST_SUFFIX}"
  fi

  echo -e "VERSION_FIXED_TAG:      [${GREEN}${VERSION_FIXED_TAG}${NC}]"
  echo -e "MAJOR_VER_FLOATING_TAG: [${GREEN}${MAJOR_VER_FLOATING_TAG}${NC}]"
  echo -e "MINOR_VER_FLOATING_TAG: [${GREEN}${MINOR_VER_FLOATING_TAG}${NC}]"

  # TODO - the major and minor floating tags assume that the release builds are
  # all done in strict sequence If say the build for v6.0.1 is re-run after the
  # build for v6.0.2 has run then v6.0-LATEST will point to v6.0.1 which is
  # incorrect, hopefully this course of events is unlikely to happen
  # shellcheck disable=SC2034
  allDockerTags=(
    "${VERSION_FIXED_TAG}"
    "${SNAPSHOT_FLOATING_TAG}"
    "${MAJOR_VER_FLOATING_TAG}"
    "${MINOR_VER_FLOATING_TAG}"
  )
}

do_versioned_stack_build() {
  local -r stack_name="$1"
  local -r scriptName="build_${stack_name}.sh"
  local -r scriptDir=${TRAVIS_BUILD_DIR}/bin/stack/
  local -r buildDir=${scriptDir}/build/

  echo -e "${GREEN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
  echo -e "${GREEN}Building and testing stack ${BLUE}${stack_name}${NC}"
  echo -e "${GREEN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"

  pushd "${scriptDir}" > /dev/null

  # Ensure there is no buildDir from a previous build
  rm -rf "${buildDir}"

  echo -e "Running ${scriptName} in ${scriptDir}"

  ./"${scriptName}" "${BUILD_VERSION}"

  pushd "${buildDir}" > /dev/null

  local -r fileName="$(ls -1 ./*.tar.gz)"

  # Now create an MD5 hash of the stack file
  local md5File="${fileName}.md5"
  echo -e "Creating MD5 hash file ${GREEN}${md5File}${NC}"
  md5sum "${fileName}" > "${md5File}"

  # Now spin up the stack to make sure it all works
  test_stack_archive "${fileName}"

  popd > /dev/null
  popd > /dev/null
}

test_stack() {
  # Bit nasty but there should only be one match in there in both cases
  pushd ./stroom_*/stroom_* > /dev/null

  # jq is installed by default on travis so no need to install it

  # Get the expected count of services
  local services_count
  # shellcheck disable=SC2002
  services_count="$(cat SERVICES.txt | wc -l)"

  echo -e "${GREEN}Running start script${NC}"
  # If the stack is unhealthy then start should exit with a non-zero code.
  ./start.sh

  assert_running_containers_count "${services_count}"

  # If this stack has a health script, run that. If the stack is unhealthy then
  # the script will exit with a non-zero code.
  if [ -f "./health.sh" ]; then
    echo -e "${GREEN}Running health script${NC}"
    ./health.sh
  fi

  # Test the restart script
  echo -e "${GREEN}Running stop script${NC}"
  ./restart.sh

  assert_running_containers_count "${services_count}"

  # Test the stop script
  echo -e "${GREEN}Running stop script${NC}"
  ./stop.sh

  assert_running_containers_count 0
  assert_all_containers_count "${services_count}"

  # Test the remove script
  echo -e "${GREEN}Running remove script${NC}"
  ./remove.sh -y

  assert_all_containers_count 0

  # Clear out all docker images/volumes/containers
  echo -e "${GREEN}Clearing out docker images/containers/volumes${NC}"
  "${TRAVIS_BUILD_DIR}"/bin/clean.sh

  popd > /dev/null
}

test_stack_archive() {
  local -r stack_archive_file=$1

  if [ ! -f "${stack_archive_file}" ]; then
    echo -e "${RED}Can't find file ${BLUE}${stack_archive_file}${NC}"
    exit 1
  fi

  # Although the stack was already exploded when it was built, we want to
  # make sure the tar.gz has everything in it.
  mkdir exploded_stack
  pushd exploded_stack > /dev/null

  echo -e "${GREEN}Exploding stack archive ${BLUE}${stack_archive_file}${NC}"
  tar -xvf "../${stack_archive_file}"

  test_stack

  popd > /dev/null
}

substitute_tag() {
  local -r tag="$1"
  local -r replacement="$2"
  local -r file="$3"
  echo -e "${GREEN}Substituting tag ${tag} with value ${BLUE}${replacement}${GREEN} in ${BLUE}${file}${NC}"
  sed -i "s/${tag}/${replacement}/" "${get_stroom_dest_file}"
}

create_get_stroom_script() {
  local -r get_stroom_filename=get_stroom.sh
  local -r script_build_dir=${TRAVIS_BUILD_DIR}/build
  local -r get_stroom_source_file=${TRAVIS_BUILD_DIR}/bin/stack/lib/${get_stroom_filename}
  local -r get_stroom_dest_file=${script_build_dir}/${get_stroom_filename}

  mkdir -p "${script_build_dir}"

  echo -e "${GREEN}Creating file ${BLUE}${get_stroom_dest_file}${GREEN} as a copy of ${BLUE}${get_stroom_source_file}${NC}"
  cp "${get_stroom_source_file}" "${get_stroom_dest_file}"

  substitute_tag "<STACK_NAME>" "${GET_STROOM_STACK_NAME}" "${get_stroom_dest_file}"
  substitute_tag "<STACK_TAG>" "${TRAVIS_TAG}" "${get_stroom_dest_file}"
  substitute_tag "<STACK_VERSION>" "${BUILD_VERSION}" "${get_stroom_dest_file}"

  # Make a copy of this script in the gh-pages dir so we can deploy it to gh-pages
  echo -e "${GREEN}Copying file ${BLUE}${get_stroom_dest_file}${GREEN} to ${BLUE}${GH_PAGES_DIR}/${NC}"
  mkdir -p "${GH_PAGES_DIR}"
  cp "${get_stroom_dest_file}" "${GH_PAGES_DIR}"/
}

dump_travis_env_vars() {
  # Dump all the travis env vars to the console for debugging, aligned with
  # the ones above
  echo -e "TRAVIS_BUILD_NUMBER:       [${GREEN}${TRAVIS_BUILD_NUMBER}${NC}]"
  echo -e "TRAVIS_COMMIT:             [${GREEN}${TRAVIS_COMMIT}${NC}]"
  echo -e "TRAVIS_BRANCH:             [${GREEN}${TRAVIS_BRANCH}${NC}]"
  echo -e "TRAVIS_TAG:                [${GREEN}${TRAVIS_TAG}${NC}]"
  echo -e "TRAVIS_PULL_REQUEST:       [${GREEN}${TRAVIS_PULL_REQUEST}${NC}]"
  echo -e "TRAVIS_EVENT_TYPE:         [${GREEN}${TRAVIS_EVENT_TYPE}${NC}]"
}

dump_build_vars() {
  # shellcheck disable=SC2153
  echo -e "STACK_NAME:                [${GREEN}${STACK_NAME}${NC}]"
  echo -e "BUILD_VERSION:             [${GREEN}${BUILD_VERSION}${NC}]"
}

