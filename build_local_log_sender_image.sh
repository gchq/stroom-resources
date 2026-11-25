#!/bin/bash


DOCKER_IMAGE_TAG="local-SNAPSHOT"
GIT_TAG="${DOCKER_IMAGE_TAG}"

main() {
  # Check for uncommitted work
  if [ "$(git status --porcelain 2>/dev/null | wc -l)" -eq 0 ]; then
      GIT_COMMIT="$(git rev-parse HEAD)"
  else
      GIT_COMMIT="unspecified"
  fi

  # '--progress=plain' stops it collapsing output in the console
  # '--no-cache' ignores cached layers so builds everything
  local extra_docker_args=(
    "--build-arg" "GIT_COMMIT=${GIT_COMMIT}"
    "--build-arg" "GIT_TAG=${GIT_TAG}"
    #"--no-cache"
    #"--progress=plain"
  )

  docker build \
      --tag gchq/stroom-log-sender:local-SNAPSHOT \
      "${extra_docker_args[@]}" \
      "$@" \
      ./stroom-log-sender
}

main "$@"
