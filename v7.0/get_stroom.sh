#!/usr/bin/env bash

############################################################################
# 
#  Copyright 2019 Crown Copyright
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# 
############################################################################

# Script to downlaod and extract a release of a stroom stack

# This script is templated and will be substituted during the build process
# To test the templated version you can do something like this:
# bash <(cat ~/git_work/stroom-resources/bin/stack/lib/get_stroom.sh | sed 's/stroom_core_test/stroom_core_test/; s/stroom-stacks-v7.0-beta.191/stroom-stacks-v6.0-beta.28-9/; s/v7.0-beta.191/v6.0-beta.28-9/; s/3258a1a46d65f24a28215b74d21380d8f9c0109a22501fcb3ab5c57be88be916  stroom_core_test-v7.0-beta.191.tar.gz/fc593474e2ee6b9a7f507303fc38522c6a4d1abf62e2ddc7af0f20d15b6baeb0  stroom_core_test-v6.0-beta.28-9.tar.gz/' )
# replacing the sed replacements

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
  local -r stack_name="stroom_core_test"
  local -r stack_tag="stroom-stacks-v7.0-beta.191"
  local -r stack_version="v7.0-beta.191"
  local -r hash_file_contents="3258a1a46d65f24a28215b74d21380d8f9c0109a22501fcb3ab5c57be88be916  stroom_core_test-v7.0-beta.191.tar.gz"

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
  local archive_file="${temp_dir}/${archive_filename}"

  # Download the file to a temporary lo
  curl --silent --location --output "${archive_file}" "${url}" 

  if [ ! -f "${archive_file}" ]; then
    echo -e "${RED}Error${GREEN}: Cannot find downloaded archive file" \
      "${BLUE}${archive_file}${NC}" >&2
    exit 1
  fi

  # Verify the archive file against the checksum
  if command -v shasum > /dev/null; then
    echo
    echo -e "${GREEN}Verifying stack archive against file hash${NC}"
    pushd "${temp_dir}" > /dev/null
    if ! echo "${hash_file_contents}" | shasum -c -s; then
      echo -e "${RED}Error${GREEN}: Archive file ${BLUE}${archive_file}${NC}" \
        "failed the checksum test using checksum" \
        "${BLUE}${hash_file_contents}${NC}" >&2
      exit 1
    fi
    popd > /dev/null
  else
    echo
    echo -e "${RED}Warning${GREEN}: Unable to verify the stack archive against" \
      "the file hash. 'shasum' isn't installed."
  fi

  echo
  echo -e "${GREEN}Unpacking stack archive${NC}"

  # Extract the stack archive file
  tar -xf "${archive_file}"

  # Delete the downloaded file and temp dir
  rm "${archive_file}"
  rmdir "${temp_dir}"

  echo
  echo -e "${GREEN}Start Stroom using ${BLUE}start.sh${GREEN} in ${BLUE}${install_dir}${NC}"
  echo -e "${GREEN}or read the ${BLUE}README.md${GREEN} file.${NC}"
  echo
}

main
