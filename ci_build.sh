#!/bin/bash

# exit script on any error
set -e

# Prefixes for git tags that determine what the build does
# Docker image prefixes
TAG_PREFIX_STROOM_LOG_SENDER="stroom-log-sender"
TAG_PREFIX_STROOM_NGINX="stroom-nginx"
TAG_PREFIX_STROOM_ZOOKEEPER="stroom-zookeeper"
TAG_PREFIX_STROOM_STACKS="stroom-stacks"

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
GET_STROOM_STACK_NAME="stroom_core_test"

GET_STROOM_FILENAME_PREFIX="get_stroom"
GET_STROOM_FILENAME="${GET_STROOM_FILENAME_PREFIX}.sh"

# The dir used to hold content for deploying to github pages, i.e.
# https://gchq.github.io/stroom-resources
GH_PAGES_DIR="${BUILD_DIR}/gh-pages"
RELEASE_ARTEFACTS_DIR="${BUILD_DIR}/release_artefacts"
SCRIPT_BUILD_DIR="${BUILD_DIR}/build"
STACK_DIR="${BUILD_DIR}/bin/stack"
STACK_BUILD_DIR="${STACK_DIR}/build"

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

# return 0 if $1 is prefixed by any of $2-$n
# e.g. is_prefixed_by "stroom-nginx-v1.2.3" "stroom-nginx" "stroom-log-sender"
is_prefixed_by() {
  if [ $# -lt 2 ]; then
    echo "Invald args to is_prefixed_by.  Args: $*"
    exit 1
  fi
  local str="$1"; shift
  
  local regex="^("
  local is_first_prefix=true
  for prefix in "$@"; do
    if [ "${is_first_prefix}" = true ]; then
      is_first_prefix=false
    else
      regex="${regex}|"
    fi
    regex="${regex}${prefix}"
  done
  regex="${regex})"

  # Now test the regex against the string
  [[ "${str}" =~ ${regex} ]]

  return $?
}

# Returns 0 if $1 is in the array of elements passed as subsequent args
# e.g. 
# arr=( "one" "two" "three" )
# element_in "two" "${arr[@]}" # returns 0
#element_in () {
  #local element 
  #local match="$1"
  #shift
  #for element; do 
    #[[ "${element}" == "${match}" ]] && return 0
  #done
  #return 1
#}

assert_all_containers_count() {
  local expected_count="$1"
  local actual_count
  actual_count="$(docker ps -a --format '{{.ID}}' | wc -l)"
  echo -e "Comparing actual container count [${GREEN}${actual_count}${NC}] to" \
    "expected [${GREEN}${expected_count}${NC}]"
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
  actual_count="$(docker ps --format '{{.ID}}' | wc -l)"
  echo -e "Comparing actual running container count" \
    "[${GREEN}${actual_count}${NC}] to expected [${GREEN}${expected_count}${NC}]"
  if [ "${actual_count}" -ne "${expected_count}" ]; then
    echo -e "${RED}Error${GREEN}:" \
      "Expecting ${BLUE}${expected_count}${GREEN} running docker containers," \
      "found ${BLUE}${actual_count}${NC}"
    return 1
  else
    return 0
  fi
}

docker_login() {
  # The username and password are configured in the travis gui
  if [[ -n "${DOCKER_USERNAME}" ]] && [[ -n "${DOCKER_PASSWORD}" ]]; then
    # Docker login stores the creds in a file so check it to
    # see if we are already logged in
    #local dockerConfigFile="${HOME}/.docker/config.json"
    #if [[ -f "${dockerConfigFile}" ]] \
      #&& grep -q "index.docker.io" "${dockerConfigFile}"; then

      #echo -e "Already logged into docker"
    #else
      echo -e "Logging in to Docker (if this fails, have you provided the" \
        "correct docker creds)"
      # Login is idempotent
      echo "${DOCKER_PASSWORD}" \
        | docker login \
          -u "${DOCKER_USERNAME}" \
          --password-stdin \
          >/dev/null 2>&1
      echo -e "Successfully logged in to docker"
    #fi
  else
    echo -e "${YELLOW}DOCKER_USERNAME and/or DOCKER_PASSWORD not set so" \
      "skipping docker login. Pulls/builds will be un-authenticated and rate" \
      "limited, pushes will fail.${NC}"
  fi
}

docker_logout() {
  # The username and password are configured in the travis gui
  if [[ -n "${DOCKER_USERNAME}" ]] && [[ -n "${DOCKER_PASSWORD}" ]]; then
    echo -e "Logging out of Docker"
    docker logout >/dev/null 2>&1
  else
    echo -e "${YELLOW}DOCKER_USERNAME and/or DOCKER_PASSWORD not set so" \
      "skipping docker logout"
  fi
}

# args: dockerRepo contextRoot tag1VersionPart tag2VersionPart ... tagNVersionPart
release_to_docker_hub() {
  # echo "releaseToDockerHub called with args [$@]"

  if [ $# -lt 3 ]; then
    echo -e "Incorrect args, expecting at least 3"
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

  docker_login

  # If we have a BUILD_TAG (git tag) then use that, else use the floating tag
  docker build \
    "${allTagArgs[@]}" \
    --build-arg GIT_COMMIT="${BUILD_COMMIT}" \
    --build-arg GIT_TAG="${BUILD_TAG:-${SNAPSHOT_FLOATING_TAG}}" \
    "${contextRoot}"

  if [[ -z "${LOCAL_BUILD}" ]]; then
    echo -e "Pushing the docker image to ${GREEN}${dockerRepo}${NC}" \
      "with tags: ${GREEN}${allTagArgs[*]}${NC}"
    docker push \
      --all-tags \
      "${dockerRepo}"
  else
    echo -e "${YELLOW}LOCAL_BUILD set so skipping push to dockerhub${NC}"
  fi

  docker_logout
}

derive_docker_tags() {
  # This is a tagged commit, so create a docker image with that tag
  VERSION_FIXED_TAG="${VERSION_NO}"

  # Extract the major version part for a floating tag
  majorVer=$(echo "${VERSION_NO}" | grep -oP "^v[0-9]+")
  if [ -n "${majorVer}" ]; then
    MAJOR_VER_FLOATING_TAG="${majorVer}${LATEST_SUFFIX}"
  fi

  # Extract the minor version part for a floating tag
  minorVer=$(echo "${VERSION_NO}" | grep -oP "^v[0-9]+\.[0-9]+")
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

do_stack_build_and_test() {
  #local -r stack_name="$1"
  local -r scriptName="build_ALL.sh"

  echo -e "Building and testing stack variants"

  pushd "${STACK_DIR}" > /dev/null

  # Ensure there is no buildDir from a previous build
  rm -rf "${STACK_BUILD_DIR}"

  echo -e "Running ${GREEN}${scriptName}${NC} in ${GREEN}${STACK_DIR}${NC}"

  # strip the "stroom-stacks-" part of the tag if it is there
  ./"${scriptName}" "${VERSION_NO}"

  pushd "${STACK_BUILD_DIR}" > /dev/null

  echo -e "Dumping build artifacts in ${GREEN}${STACK_BUILD_DIR}${NC}"
  ls -1 "${STACK_BUILD_DIR}"

  for archive_filename in *.tar.gz; do
    # Now spin up the stack to make sure it all works
    # TODO we can't test stroom_services as it won't run without a database
    # TODO we can't test stroom_full* as it will blow travis' memory
    # TODO we can't test stroom_and_proxy as proxy tries to get feed status
    # from nginx
    # We can't test 'stroom' stack as it has no DB
    if [[ "${archive_filename}" =~ ^stroom_(core|core_test|dbs)?- ]]; then
      test_stack_archive "${archive_filename}"
    else
      echo -e "Skipping stack tests for ${GREEN}${archive_filename}${NC}"
    fi
  done

  # popd intentionally twice
  popd > /dev/null
  popd > /dev/null
}

add_env_file_line() {
  local env_file="$1"; shift
  local env_var_line="$1"; shift
  
  echo -e "${RED}Adding ${YELLOW}${env_var_line}" \
    "${RED}to ${BLUE}${env_file}${RED} to allow the stack to be tested by the CI build${NC}"

  echo "${env_var_line}" >> "${env_file}"
}

test_stack() {
  stack_name="$1"
  echo -e "Testing stack ${GREEN}${stack_name}${NC} - ${GREEN}${VERSION_NO}${NC}"

  # Bit nasty but there should only be one match in there in both cases
  pushd "./${stack_name}-${VERSION_NO}" > /dev/null

  echo -e "In directory ${GREEN}$(pwd)${NC}"

  # Get the expected count of services
  local services_count
  # shellcheck disable=SC2002
  services_count="$(cat ALL_SERVICES.txt | wc -l)"
  echo -e "services_count:            [${GREEN}${services_count}${NC}]"

  local env_file="config/${stack_name}.env"
  # In order for the stack to start up cleanly and for the health
  # check not fail we need to run with hard coded insecure open id creds.
  # Some stacks already have this set, i.e. the -test stacks.
  echo -e "${RED}********************************************************************************${NC}"
  # This one is for stroom v7.2
  add_env_file_line "${env_file}" "export STROOM_IDENTITY_PROVIDER_TYPE=\"TEST_CREDENTIALS\""
  # This one is for stroom-proxy v7.0
  add_env_file_line "${env_file}" "export USE_DEFAULT_OPEN_ID_CREDENTIALS=\"true\""
  echo -e "${RED}********************************************************************************${NC}"

  ./info.sh

  ./pull_images.sh

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

  ./status.sh

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
  echo -e "${GREEN}Clearing out all docker images/containers/volumes${NC}"
  "${BUILD_DIR}"/bin/clean.sh

  popd > /dev/null
}

test_stack_archive() {
  local -r stack_archive_file=$1

  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
  echo -e "Testing stack archive ${GREEN}${stack_archive_file}${NC}"

  if [ ! -f "${stack_archive_file}" ]; then
    echo -e "${RED}Can't find file ${BLUE}${stack_archive_file}${NC}"
    exit 1
  fi

  # Although the stack was already exploded when it was built, we want to
  # make sure the tar.gz has everything in it.
  mkdir -p _exploded
  local exploded_dir
  exploded_dir="$(mktemp -d --tmpdir=_exploded)"
  echo -e "Using temp dir ${exploded_dir}"
  pushd "${exploded_dir}" > /dev/null

  echo -e "${GREEN}Exploding stack archive ${BLUE}${stack_archive_file}${NC}"
  tar -xvf "../../${stack_archive_file}"

  stack_name="${stack_archive_file%%-*}"

  test_stack "${stack_name}"

  popd > /dev/null
  echo -e "${GREEN}--------------------------------------------------------------------------------${NC}"
}

substitute_tag() {
  local -r tag="$1"
  local -r replacement="$2"
  local -r file="$3"
  echo -e "${GREEN}Substituting tag ${tag} with value" \
    "${BLUE}${replacement}${GREEN} in ${BLUE}${file}${NC}"
  sed -i "s/${tag}/${replacement}/" "${get_stroom_dest_file}"
}

# Creates a script (from a template) that can be used to download a specific
# stack variant and version, check it against a hash and then explode it.
create_get_stroom_script() {

  local -r get_stroom_source_file="${BUILD_DIR}/bin/stack/lib/${GET_STROOM_FILENAME}"
  local -r hash_file="${STACK_BUILD_DIR}/${GET_STROOM_STACK_NAME}-${VERSION_NO}.tar.gz.sha256"

  local -r get_stroom_dest_file="${SCRIPT_BUILD_DIR}/${GET_STROOM_FILENAME}"

  mkdir -p "${SCRIPT_BUILD_DIR}"

  if [ ! -f "${hash_file}" ]; then
    echo -e "${RED}ERROR${NC}: Can't find hash file ${GREEN}${hash_file}${NC}"
    exit 1
  fi

  # Get the content of the hashsum file
  local hash_file_contents
  hash_file_contents="$(<"${hash_file}")"

  echo -e "${GREEN}Creating file ${BLUE}${get_stroom_dest_file}${GREEN} as a" \
    "copy of ${BLUE}${get_stroom_source_file}${NC}"
  cp "${get_stroom_source_file}" "${get_stroom_dest_file}"

  substitute_tag "<STACK_NAME>" "${GET_STROOM_STACK_NAME}" "${get_stroom_dest_file}"
  substitute_tag "<STACK_TAG>" "${BUILD_TAG}" "${get_stroom_dest_file}"
  substitute_tag "<STACK_VERSION>" "${VERSION_NO}" "${get_stroom_dest_file}"
  substitute_tag "<HASH_FILE_CONTENTS>" "${hash_file_contents}" "${get_stroom_dest_file}"

  # Make a copy of this script in the gh-pages dir so we can deploy it to gh-pages
  # Github actions will update the gh-pages branch
  echo -e "${GREEN}Copying file ${BLUE}${get_stroom_dest_file}${GREEN} to" \
    "${BLUE}${GH_PAGES_DIR}/${NC}"

  mkdir -p "${GH_PAGES_DIR}"

  cp \
    "${get_stroom_dest_file}" \
    "${GH_PAGES_DIR}"/

  # Now copy the file to the release artefacts dir so it is added as a release
  # asset in github
  echo -e "${GREEN}Copying file ${BLUE}${get_stroom_dest_file}${GREEN} to" \
    "${BLUE}${RELEASE_ARTEFACTS_DIR}/${NC}"
  mkdir -p "${RELEASE_ARTEFACTS_DIR}"
  cp \
    "${get_stroom_dest_file}" \
    "${RELEASE_ARTEFACTS_DIR}/${GET_STROOM_FILENAME}"
}

dump_travis_env_vars() {
  # Dump all the travis env vars to the console for debugging, aligned with
  # the ones above
  echo -e "BUILD_COMMIT:             [${GREEN}${BUILD_COMMIT}${NC}]"
  echo -e "BUILD_BRANCH:             [${GREEN}${BUILD_BRANCH}${NC}]"
  echo -e "BUILD_TAG:                [${GREEN}${BUILD_TAG}${NC}]"
  echo -e "BUILD_IS_PULL_REQUEST:    [${GREEN}${BUILD_IS_PULL_REQUEST}${NC}]"
}

dump_build_vars() {
  # shellcheck disable=SC2153
  echo -e "STACK_NAME:                [${GREEN}${STACK_NAME}${NC}]"
  echo -e "BUILD_VERSION:             [${GREEN}${BUILD_VERSION}${NC}]"
  echo -e "VERSION_NO:                [${GREEN}${VERSION_NO}${NC}]"
}

do_release() {

  # Tagged commit so use that as our build version, e.g. v6.0.0
  # shellcheck disable=SC2034
  local -r tag_prefix="$(echo "${BUILD_TAG}" | grep -oP "${PREFIX_PART_REGEX}")"

  dump_build_vars
  echo -e "tag_prefix:                [${GREEN}${tag_prefix}${NC}]"

  if [[ ${BUILD_TAG} =~ ${TAG_PREFIX_STROOM_NGINX} ]]; then
    # This is a stroom-nginx release, so do a docker build/push
    echo -e "${GREEN}Performing a ${BLUE}stroom-nginx${GREEN} release" \
      "to dockerhub${NC}"

    derive_docker_tags

    # build and release the image to dockerhub
    # shellcheck disable=SC2154
    release_to_docker_hub \
      "${DOCKER_REPO_STROOM_NGINX}" \
      "${DOCKER_CONTEXT_ROOT_STROOM_NGINX}" \
      "${allDockerTags[@]}"

  elif [[ ${BUILD_TAG} =~ ${TAG_PREFIX_STROOM_LOG_SENDER} ]]; then
    # This is a stroom-log-sender release, so do a docker build/push
    echo -e "${GREEN}Performing a ${BLUE}stroom-log-sender${GREEN} release" \
      "to dockerhub${NC}"

    derive_docker_tags

    # build and release the image to dockerhub
    release_to_docker_hub \
      "${DOCKER_REPO_STROOM_LOG_SENDER}" \
      "${DOCKER_CONTEXT_ROOT_STROOM_LOG_SENDER}" \
      "${allDockerTags[@]}"

  elif [[ ${BUILD_TAG} =~ ${TAG_PREFIX_STROOM_ZOOKEEPER} ]]; then
    # This is a stroom-zookeeper release, so do a docker build/push
    echo -e "${GREEN}Performing a ${BLUE}stroom-zookeeper${GREEN} release" \
      "to dockerhub${NC}"

    derive_docker_tags

    # build and release the image to dockerhub
    release_to_docker_hub \
      "${DOCKER_REPO_STROOM_ZOOKEEPER}" \
      "${DOCKER_CONTEXT_ROOT_STROOM_ZOOKEEPER}" \
      "${allDockerTags[@]}"

  elif [[ ${BUILD_TAG} =~ ${TAG_PREFIX_STROOM_STACKS} ]]; then
    echo -e "${GREEN}Performing a ${BLUE}${tag_prefix}${GREEN} stack" \
      "release to github${NC}"

    create_get_stroom_script

    gather_release_artefacts
  fi
}

# Put all release artefacts in a dir to make it easier to upload them to
# Github releases.
gather_release_artefacts() {
  mkdir -p "${RELEASE_ARTEFACTS_DIR}"

  echo "Copying release artefacts to ${RELEASE_ARTEFACTS_DIR}"

  # Copy the stack archives and their hashes
  echo "Copy stack archives"
  cp \
    "${STACK_BUILD_DIR}/"*.tar.gz* \
    "${RELEASE_ARTEFACTS_DIR}/"

  # The copy of get_stroom.sh is done in create_get_stroom_script()
}

main() {
  setup_colours
  dump_travis_env_vars

  # shellcheck disable=SC2034
  BUILD_VERSION="${BUILD_TAG:-SNAPSHOT}"
  # VERSION_NO is just the number part of the tag without the prefix
  # e.g. v6.0-beta.52
  VERSION_NO="$( \
    echo "${BUILD_VERSION}"  \
    | grep -oP "(${VERSION_PART_REGEX}|SNAPSHOT)" \
    )"

  dump_build_vars

  echo -e "Logging in to DockerHub"
  docker_login

  # If we are releasing a new docker image then that version will not be available
  # on Dockerhub to be able to test the stack against it 
  if [ -n "${BUILD_TAG}" ] && \
     is_prefixed_by \
      "${BUILD_TAG}" \
      "${TAG_PREFIX_STROOM_NGINX}" \
      "${TAG_PREFIX_STROOM_ZOOKEEPER}" \
      "${TAG_PREFIX_STROOM_LOG_SENDER}"; then
    echo "This is a docker image build so don't test the stack"
  else
    # STACK_NAME is set by the travis build matrix
    # shellcheck disable=SC2153
    do_stack_build_and_test
  fi

  # Perform a release to github/dockerhub if required
  if [ -n "$BUILD_TAG" ] && [[ "$BUILD_TAG" =~ ${RELEASE_VERSION_REGEX} ]] ; then
    do_release
  else
    echo -e "${GREEN}${BUILD_TAG} is not a tagged commit (or a tag we" \
      "recognise), nothing to release.${NC}"
  fi

  docker_logout
}

# Start of script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main "$@"

exit 0
