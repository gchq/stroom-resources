#!/bin/bash

############################################################################
# 
#  Copyright 2020 Crown Copyright
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
###########################################################################

# This script populates the create databases template with default values
# in order to produce an sql file suitable for use outside of a docker
# enviromnent (suitable for test puposes)


# Function to take a file containing tags of the form <<<MY_TAG>>>.
# Each tag will be replaced by the value of an ennvironemnt variable
# with the same name. This allows sql scripts to be run that use environment
# variables passed into the container. The template file will not be mutated.
process_template_file() {
  local template_file="$1"
  echo "Processing template file ${template_file}"

  # Strip .template off the end
  local output_file
  output_file="$2"

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

  echo "Using sed arguments:" "${sed_args[@]}"

  sed "${sed_args[@]}" "${template_file}" > "${output_file}"

  echo "Completed substitutions. Dumping contents of ${output_file}"
  echo "====================================================================="
  cat "${output_file}"
  echo "====================================================================="
}



export STROOM_ANNOTATIONS_DB_NAME='annotations'
export STROOM_ANNOTATIONS_DB_USERNAME='annotationsuser'
export STROOM_ANNOTATIONS_DB_PASSWORD='stroompassword1'
#Auth
export STROOM_AUTH_DB_NAME='auth'
export STROOM_AUTH_DB_USERNAME='authuser'
export STROOM_AUTH_DB_PASSWORD='stroompassword1'
#config
export STROOM_CONFIG_DB_NAME='config'
export STROOM_CONFIG_DB_USERNAME='configuser'
export STROOM_CONFIG_DB_PASSWORD='stroompassword1'
#datameta
export STROOM_DATAMETA_DB_NAME='datameta'
export STROOM_DATAMETA_DB_USERNAME='datametauser'
export STROOM_DATAMETA_DB_PASSWORD='stroompassword1'
#explorer
export STROOM_EXPLORER_DB_NAME='explorer'
export STROOM_EXPLORER_DB_USERNAME='exploreruser'
export STROOM_EXPLORER_DB_PASSWORD='stroompassword1'
#process
export STROOM_PROCESS_DB_NAME='process'
export STROOM_PROCESS_DB_USERNAME='processuser'
export STROOM_PROCESS_DB_PASSWORD='stroompassword1'
#stats
export STROOM_STATS_DB_NAME='stats'
export STROOM_STATS_DB_USERNAME='statsuser'
export STROOM_STATS_DB_PASSWORD='stroompassword1'
#stroom
export STROOM_DB_NAME='stroom'
export STROOM_DB_USERNAME='stroomuser'
export STROOM_DB_PASSWORD='stroompassword1'

process_template_file ../../dev-resources/compose/volumes/stroom-all-dbs/init/stroom/001_create_databases.sql.template \
    ./create_databases.sql
