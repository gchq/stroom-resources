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

  local temp_dir
  temp_dir="$(mktemp -d)"

  local output_file_name
  output_file_name="$(basename "${template_file%.template}")"
  local output_file="${temp_dir}/${output_file_name}"

  if [ -f "${output_file}" ] ; then
    # Should never happen given we are using mktemp
    echo "Output file ${output_file} already exists, quitting!"
    exit 1
  fi

  cat "${template_file}" > "${output_file}"

  local all_substitution_variables
  all_substitution_variables="$( \
    grep -oP "<<<[^>]+>>>" "${template_file}" \
      | sort \
      | uniq
    )"

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
    sed -i'' "s|${tag}|${value}|g" "${output_file}"

  done <<< "${all_substitution_variables}"

  echo "Completed substitutions. Dumping contents of ${output_file}"
  echo "====================================================================="
  cat "${output_file}"
  echo "====================================================================="

  # Now we have substituted the values call process_init_file again
  echo "Calling process_init_file on ${output_file}"
  echo

  # ${mysql[@]} is set in the original call to process_init_file
  # If we don't pass it back in the connection details will be unavailable
  process_init_file "${output_file}" "${mysql[@]}"
  echo "Deleting directory ${temp_dir}"
  rm -rf "${temp_dir}"
}


# IMPORTANT: This function overrides the one declared in
# /usr/local/bin/docker-entrypoint.sh (in the container)
# to provide more functionality:
#   - The additional handling of .template files
#   - The passing of mysql[@] to the .sh file
# files. It will be called for each file found in 
# /docker-entrypoint-initdb.d/
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# usage: process_init_file FILENAME MYSQLCOMMAND...
#    ie: process_init_file foo.sh mysql -uroot
# (process a single initializer file, based on its extension. we define this
# function here, so that initializer scripts (*.sh) can use the same logic,
# potentially recursively, or override the logic used in subsequent calls)
process_init_file() {
  local file="$1"; shift
  local mysql=( "$@" )

  #echo "mysql: [${mysql[*]}]"

  case "${file}" in
    *.sh)       echo "$0: running ${file}"; . "${file}" ;;
    *.sql)      echo "$0: running ${file}"; "${mysql[@]}" < "${file}"; echo ;;
    *.sql.gz)   echo "$0: running ${file}"; gunzip -c "${file}" | "${mysql[@]}"; echo ;;
    *.template) echo "$0: processing ${file}"; process_template_file "${file}";;
    *)          echo "$0: ignoring ${file}" ;;
  esac
  echo
}

