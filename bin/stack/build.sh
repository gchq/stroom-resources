#!/usr/bin/env bash
#
# Builds a Stroom stack 

set -e

# shellcheck disable=SC1091
source lib/shell_utils.sh
setup_echo_colours

validate_requested_services() {
  local -r VALID_SERVICES=( \
    "elasticsearch" \
    "fake-smtp" \
    "hbase" \
    "hdfs" \
    "kafka" \
    "kibana" \
    "nginx" \
    "stroom" \
    "stroom-all-dbs" \
    "stroom-log-sender" \
    "stroom-proxy-local" \
    "stroom-proxy-remote" \
    "stroom-query-elastic-service" \
    "stroom-query-elastic-ui" \
    "stroom-stats" \
    "zookeeper" \
  )

  for service in "${@}"; do
    if ! element_in "${service}" "${VALID_SERVICES[@]}"; then
      err "${RED}'${service}'${NC} is not a valid service! Valid services are:"
      for valid_service in "${VALID_SERVICES[@]}"; do
        err "  ${BLUE}${valid_service}${NC}" 
      done
      exit 1
    fi
  done
}

# Produce a file containing the list of services in the stack
# so the stack can use it to tailor how the start/stop/etc. scripts
# operate
#create_services_file() {
  #touch "${SERVICES_FILE}"
  #for service in "${SERVICES[@]}"; do
    #echo "${service}" >> "${SERVICES_FILE}"
  #done
#}


main() {
  [ "$#" -ge 3 ] || die "${RED}Error${NC}: Invalid arguments, usage: ${BLUE}build.sh stackName version serviceX serviceY etc.${NC}"

  # Some of the scripts use associataive arrays which are bash 4 only.
  test_for_bash_version_4

  check_binary_is_available "jq"
  check_binary_is_available "ruby"
  check_binary_is_available "docker-compose"

  local -r BUILD_STACK_NAME=$1
  local -r VERSION=$2
  local -r SERVICES=("${@:3}")
  local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
  local -r STACK_DIR_NAME="${BUILD_STACK_NAME}-${VERSION}"
  local -r ARCHIVE_NAME="${STACK_DIR_NAME}.tar.gz"
  local -r HASH_FILE_NAME="${ARCHIVE_NAME}.sha256"
  local -r WORKING_DIRECTORY="${BUILD_DIRECTORY}/${STACK_DIR_NAME}"
  local -r SERVICES_FILE="${WORKING_DIRECTORY}/SERVICES.txt"

  if [ -d "${BUILD_DIRECTORY}" ];then
    die "${RED}Error${NC}: Build directory ${BLUE}${BUILD_DIRECTORY}${NC} already exists, please delete it first.${NC}"
  fi

  mkdir -p "$WORKING_DIRECTORY"

  validate_requested_services "${SERVICES[@]}"

  echo -e "${GREEN}Creating a stack called ${YELLOW}${BUILD_STACK_NAME}${GREEN} with version ${YELLOW}${VERSION}${GREEN} and the following services:${NC}"
  for service in "${SERVICES[@]}"; do
    echo -e "  ${BLUE}${service}${NC}"
  done

  #create_services_file

  ./create_stack_yaml.sh "${BUILD_STACK_NAME}" "${VERSION}" "${SERVICES[@]}"
  ./create_stack_env.sh "${BUILD_STACK_NAME}" "${VERSION}" "${SERVICES[@]}"
  ./create_stack_scripts.sh "${BUILD_STACK_NAME}" "${VERSION}" "${SERVICES[@]}"
  ./create_stack_assets.sh "${BUILD_STACK_NAME}" "${VERSION}" "${SERVICES[@]}"

  echo -e "${GREEN}Creating ${BLUE}${BUILD_DIRECTORY}/${ARCHIVE_NAME}${NC}"
  #pushd "${BUILD_DIRECTORY}" > /dev/null
  pushd build
  tar -zcf "${ARCHIVE_NAME}" "./${STACK_DIR_NAME}"

  echo -e "${GREEN}Creating ${BLUE}${BUILD_DIRECTORY}/${HASH_FILE_NAME}${NC}"
  shasum -a 256 "${ARCHIVE_NAME}" > "${HASH_FILE_NAME}"

  popd > /dev/null

  echo -e "${GREEN}Build complete!${NC}"
}

main "$@"
