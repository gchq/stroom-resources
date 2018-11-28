#!/usr/bin/env bash
#
# Builds a Stroom stack 

set -e

source lib/shell_utils.sh
setup_echo_colours

main() {
    [ "$#" -ge 3 ] || die "${RED}Error${NC}: Invalid arguments, usage: ${BLUE}build.sh stackName version serviceX serviceY etc.${NC}"

    local -r BUILD_STACK_NAME=$1
    local -r VERSION=$2
    local -r SERVICES=( "${@:3}" )

    ./create_stack_yaml.sh "${BUILD_STACK_NAME}" "${VERSION}" "${SERVICES[@]}"
    ./create_stack_env.sh "${BUILD_STACK_NAME}" "${VERSION}"
    ./create_stack_scripts.sh "${BUILD_STACK_NAME}" "${VERSION}"
    ./create_stack_assets.sh "${BUILD_STACK_NAME}" "${VERSION}" "${SERVICES[@]}"

    local -r BUILD_DIRECTORY="build/${BUILD_STACK_NAME}"
    local -r ARCHIVE_NAME="${BUILD_STACK_NAME}-${VERSION}.tar.gz"
    echo -e "${GREEN}Creating ${BUILD_DIRECTORY}/${ARCHIVE_NAME} ${NC}"
    pushd build > /dev/null
    tar -zcf "${ARCHIVE_NAME}" "./${BUILD_STACK_NAME}"
    popd > /dev/null
}

main "$@"
