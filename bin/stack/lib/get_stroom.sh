#!/usr/bin/env bash

# Script to downlaod and extract a release of a stroom stack

# This script is templated and will be substituted during the build process

# Exit the script on any error
set -e

#Shell Colour constants for use in 'echo -e'
#RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
#LGREY='\e[37m'
#DGREY='\e[90m'
NC='\033[0m' # No Colour

main() {
  # stack_version will be hard coded by TravisCI at build time
  local -r stack_name="<STACK_NAME>"
  local -r stack_tag="<STACK_TAG>"
  local -r stack_version="<STACK_VERSION>"
  local -r hash_file_contents="<HASH_FILE_CONTENTS>"

  local -r install_dir="./${stack_name}/${stack_tag}"
  local -r archive_filename="${stack_name}-${stack_version}.tar.gz"
  local -r url="https://github.com/gchq/stroom-resources/releases/download/${stack_tag}/${archive_filename}"

  if [ "$(find . -name "stroom_*" | wc -l)" -gt 0 ] || [ -d ./volumes ]; then
    echo -e "${YELLOW}WARNING${GREEN}: It looks like you already have an existing stack installed.${NC}"
    echo -e "${GREEN}If you proceed, your configuration will be replaced/updated but data will be left as is.${NC}"
    echo -e "${GREEN}If the existing stack is running, you should stop it first${NC}"
    echo
  fi

  echo
  echo -e "${GREEN}This script will download the Stroom stack ${BLUE}${stack_version}${NC}"
  echo -e "${GREEN}into the current directory.${NC}"

  echo
  read -rsp $'Press "y" to continue, any other key to cancel.\n' -n1 keyPressed

  if [ "${keyPressed}" = 'y' ] || [ "${keyPressed}" = 'Y' ]; then
    echo
  else
    echo
    echo "Exiting"
    exit 0
  fi

  # Verify the url exists
  if ! curl --output /dev/null --silent --head --fail "${url}"; then
    echo -e "${RED}Error${GREEN}: The file at URL ${BLUE}${url}${GREEN}" \
      "doesn't exist${NC}" >&2
    exit 1
  fi

  echo
  echo -e "${GREEN}Downloading stack archive from ${BLUE}${url}${NC}"

  local temp_dir
  temp_dir="$(mktemp -d)"
  local archive_file="${temp_dir}/${archive_file}"

  # Download the file to a temporary lo
  curl --silent --location --output "${archive_file}" "${url}" 

  if [ ! -f "${archive_file}" ]; then
    echo -e "${RED}Error${GREEN}: Cannot find downloaded archive file" \
      "${BLUE}${archive_file}${NC}" >&2
    exit 1
  fi

  # Verify the archive file against the checksum
  if command -v shasum; then
    echo
    echo -e "${GREEN}Verifying stack archive against file hash"
    if ! echo "${hash_file_contents}" | shasum -c -s; then
      echo -e "${RED}Error${GREEN}: Archive file ${BLUE}${archive_file}${NC}" \
        "failed the checksum test using checksum" \
        "${BLUE}${hash_file_contents}${NC}" >&2
      exit 1
    fi
  else
    echo
    echo -e "${RED}Warning${GREEN}: Unable to verify the stack archive against" \
      "the file hash. 'shasum' isn't installed."
  fi

  echo
  echo -e "${GREEN}Unpacking stack archive"

  # Extract the stack archive file
  tar xz "${archive_file}"

  # Delete the downloaded file and temp dir
  rm "${archive_file}"
  rmdir "${temp_dir}"

  echo
  echo -e "${GREEN}Start Stroom using ${BLUE}start.sh${GREEN} in ${BLUE}${install_dir}${NC}"
  echo -e "${GREEN}or read the ${BLUE}README.md${GREEN} file.${NC}"
  echo
}

main
