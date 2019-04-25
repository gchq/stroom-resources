#!/bin/bash

set -e

create_nginx_conf() {
  echo "Substituting tags in ${nginx_conf_template_file} to generate ${nginx_conf_file}"

  cat "${nginx_conf_template_file}" > "${nginx_conf_file}"

  # Find all the distinct <<<SOME_TAG>>> type tags in the template file
  unique_tags_in_file="$( \
    grep -oP "<<<[^<]+>>>" "${nginx_conf_template_file}" \
    | sort \
    | uniq \
  )"

  is_tag_replacement_missing=false

  if [ -n "${unique_tags_in_file}" ]; then
    while read -r tag; do
      local tag_name
      tag_name="$(echo "${tag}" | sed -E 's/[<>]{3}//g')"

      local replacement_value="${!tag}"

      if [ -n "${replacement_value}" ]; then
        echo "  Replacing tag ${tag_name} with value [${replacement_value}]"

        sed -i'' "s|${tag}|${replacement_value}|g" "${nginx_conf_file}"
      else
        echo "ERROR: No substitution value for tag ${tag_name}"
        is_tag_replacement_missing=true
      fi
    done <<< "${unique_tags_in_file}"

    if [ "${is_tag_replacement_missing}" = false ]; then
      echo "One or more substitution tags were missing so exiting"
      exit 1
    fi
  fi
}

setup_logrotate() {
  if [ -f "${logrotate_template_file}" ]; then

    echo "Creating ${logrotate_conf_file} from ${logrotate_template_file}"
    cp "${logrotate_template_file}" "${logrotate_conf_file}"
    # logrotate is fussy about the ownership/permissions of the conf file
    chmod -R 400 "${logrotate_conf_file}"

  else
    echo "WARN: logrotate template file ${logrotate_template_file} not found, nginx logs won't be rotated"
  fi
}

setup_crontab() {
  if [ -f "${crontab_file}" ]; then
    echo "(Re-)setting crontab to:"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat "${crontab_file}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # If we assign the crontab to the 'sender' user (crontab -u ...) it won't work, 
    # as sender dosn't have perms on /dev/stdout
    # Instead, consider using supercronic - https://github.com/aptible/supercronic/ so that
    # we can run as non-root
    /usr/bin/crontab "${crontab_file}"

    # start crond as root
    echo "Starting crond in the background"

    /usr/sbin/crond -l 8 && \
      echo "Starting CMD: [" "$@" "]" && \
      exec "$@"
  else
    echo "WARN: crontab file ${crontab_file} not found, can't start cron, nginx logs won't be rotated"
    # Now run the CMD
    echo "Starting CMD: [" "$@" "]"
    exec "$@"
  fi
}

main() {
  base_dir="/stroom-nginx"
  logs_dir="${base_dir}/logs"
  config_dir="${base_dir}/config"
  log_sender_headers_file="${logs_dir}/extra_headers.txt"
  crontab_file="${config_dir}/crontab.txt"
  logrotate_template_file="${config_dir}/logrotate.conf.template"
  logrotate_conf_file="${base_dir}/logrotate/logrotate.conf"

  nginx_conf_template_file="${config_dir}/nginx.conf.template"
  nginx_conf_file="/etc/nginx/nginx.conf"

  create_nginx_conf

  echo "Ensuring directories"
  # Ensure we have the sub-directories in our /nginx/logs/ volume
  mkdir -p "${logs_dir}/access"
  mkdir -p "${logs_dir}/app"

  # shellcheck disable=SC1090
  . "${base_dir}/add_container_identity_headers.sh" "${log_sender_headers_file}"

  setup_logrotate
  setup_crontab "$@"
}

main "$@"

# vim: set shiftwidth=2 tabstop=2:
