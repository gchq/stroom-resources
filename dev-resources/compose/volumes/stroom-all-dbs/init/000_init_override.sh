#!/usr/bin/env bash

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
    #echo "Substituting tag ${tag}"
    local tag_name
    # shellcheck disable=SC2001
    tag_name="$(echo "${tag}" | sed -E "s/[<>]{3}//g")"
    # Use bash indirection to get the value of the variable
    #echo "Substituting tag ${tag_name}"
    local value="${!tag_name}"
    echo "Substituting tag ${tag} for value [${value}]"

    if [ ! -n "${value}" ]; then
      echo "WARNING: No value for variable ${tag_name}, replacing with nothing"
    fi

    # Replace the tag with its value
    sed -i'' "s|${tag}|${value}|g" "${output_file}"

  done <<< "${all_substitution_variables}"

  echo "Completed substitutions. Dumping contents of ${output_file}"
  echo "-----------------------------------------------------------"
  cat "${output_file}"
  echo "-----------------------------------------------------------"

  # Now we have substituted the values call process_init_file again
  echo "Calling process_init_file on ${output_file}"
  echo
  # ${mysql[@]} is set in the original call to process_init_file
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
  local f="$1"; shift
  local mysql=( "$@" )

  #echo "mysql: [${mysql[*]}]"

  case "$f" in
    *.sh)       echo "$0: running $f"; . "$f" ;;
    *.sql)      echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
    *.sql.gz)   echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
    *.template) echo "$0: processing $f"; process_template_file "$f";;
    *)          echo "$0: ignoring $f" ;;
  esac
  echo
}

