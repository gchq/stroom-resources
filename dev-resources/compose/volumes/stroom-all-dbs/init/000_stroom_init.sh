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

# Function to take a file containing tags of the form <<<MY_TAG>>>.
# Each tag will be replaced by the value of an ennvironemnt variable
# with the same name. This allows sql scripts to be run that use environment
# variables passed into the container. The template file will not be mutated.
process_template_file() {
  local template_file="$1"; shift
  echo "Processing template file ${template_file}"

  # Strip .template off the end
  local output_file
  output_file="${template_file%.template}"

  #cp "${template_file}" "${output_file}"

  if [ -f "${output_file}" ] ; then
    echo "Output file ${output_file} already exists, quitting!"
    exit 1
  fi

  local all_substitution_variables
  all_substitution_variables="$( \
    grep -oP "<<<[^>]+>>>" "${template_file}" \
      | sort \
      | uniq
    )"

  sed_args=( )
  while read tag; do
    local tag_name
    # shellcheck disable=SC2001
    tag_name="$(echo "${tag}" | sed -E "s/[<>]{3}//g")"
    # Use bash indirection to get the value of the variable
    local value="${!tag_name}"
    if [ ! -n "${value}" ]; then
      echo "WARNING: No value for variable ${tag_name}, replacing with nothing"
    fi
    echo "Substituting tag ${tag} with value [${value}]"

    # Replace the tag with its value
    sed_args+=( "-e" "s|${tag}|${value}|g" )

  done <<< "${all_substitution_variables}"

  #echo "Using sed arguments:" "${sed_args[@]}"

  sed "${sed_args[@]}" "${template_file}" > "${output_file}"

  echo "Deleting ${template_file}"
  rm "${template_file}"

  echo "Completed substitutions. Dumping contents of ${output_file}"
  echo "====================================================================="
  cat "${output_file}"
  echo "====================================================================="
}

main () {

  # MySQL's entrypoint script will only process files in the root of
  # /docker-entrypoint-initdb.d/ so we put all our files in a sub dir
  # and then call there function to process them
  local init_dir="/docker-entrypoint-initdb.d/stroom"
  local temp_dir
  temp_dir="$(mktemp -d)"
  echo "Created temp directory ${temp_dir}"

  # The file system is read-only so have to create our files in /tmp
  cp "${init_dir}"/* "${temp_dir}/"

  for template_file in ${temp_dir}/*.template; do
    process_template_file "${template_file}"
  done

  # Now we have substituted the values call process_init_file again
  echo "Calling docker_process_init_files on ${temp_dir}/*"
  echo

  # **************************************************************
  # IMPORTANT: This function is declared in
  # /usr/local/bin/docker-entrypoint.sh (in the container)
  # If MySQL change that script then this may need to change
  # Very fragile, not ideal.
  # **************************************************************
  #
  # Now we have processed out template files run mysql's function 
  # on our sub dir that contains the results of that templating and
  # any other files.
  docker_process_init_files "${temp_dir}"/*

  echo "Deleting temp directory ${temp_dir}"
  rm -rf "${temp_dir}"
}

main "$@"

echo "Finished $0"
