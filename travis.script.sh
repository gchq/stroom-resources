#!/bin/bash

# exit script on any error
set -e

# shellcheck disable=SC1091
source travis.common.sh

main() {
  setup_colours
  dump_travis_env_vars

  # TODO probably want to build the stacks regardless, possibly as travis
  # build jobs/stages prior to a deploy stage
  # see https://docs.travis-ci.com/user/build-stages/matrix-expansion/
  # shellcheck disable=SC2034
  BUILD_VERSION="SNAPSHOT"

  dump_build_vars

  # No tag so finish
  echo -e "Not a tagged build so just build the stack and test it"

  # STACK_NAME is set by the travis build matrix
  # shellcheck disable=SC2153
  do_versioned_stack_build "${STACK_NAME}"
}

# Start of script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main "$@"

exit 0
