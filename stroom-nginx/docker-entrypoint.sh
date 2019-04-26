#!/bin/bash

set -e

setup_colours() {
  # Shell Colour constants for use in 'echo -e'
  # e.g.  echo -e "My message ${GREEN}with just this text in green${NC}"
  # shellcheck disable=SC2034
  {
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    NC='\033[0m' # No Colour 
  }
}

create_nginx_conf() {
  echo -e "Substituting tags in ${BLUE}${nginx_conf_template_file}${NC}" \
    "to generate ${BLUE}${nginx_conf_file}${NC}"

  cat "${nginx_conf_template_file}" > "${nginx_conf_file}"

  # Find all the distinct <<<SOME_TAG>>> type tags in the template file
  unique_tags_in_file="$( \
    grep -oE "<<<[^<]+>>>" "${nginx_conf_template_file}" \
    | sort \
    | uniq \
  )"

  if [ -n "${unique_tags_in_file}" ]; then
    while read -r tag; do
      local tag_name
      tag_name="$(echo -e "${tag}" | sed -E 's/[<>]{3}//g')"
      #echo -e "tag_name: ${tag_name}"

      local replacement_value="${!tag_name}"
      #echo -e "replacement_value: ${replacement_value}"

      echo -e "  Replacing tag ${YELLOW}${tag_name}${NC} with value" \
        "[${GREEN}${replacement_value}${NC}]"

      sed -i'' "s|${tag}|${replacement_value}|g" "${nginx_conf_file}"

      if [ ! -n "${replacement_value}" ]; then
        echo -e "  ${RED}WARN${NC}: No substitution value for" \
          "tag ${YELLOW}${tag_name}${NC}, nginx may not start!"
      fi
    done <<< "${unique_tags_in_file}"
  fi
}

setup_logrotate() {
  if [ -f "${logrotate_template_file}" ]; then

    echo -e "Creating ${BLUE}${logrotate_conf_file}${NC} from" \
      "${BLUE}${logrotate_template_file}${NC}"
    cp "${logrotate_template_file}" "${logrotate_conf_file}"
    # logrotate is fussy about the ownership/permissions of the conf file
    chmod -R 400 "${logrotate_conf_file}"

  else
    echo -e "${RED}WARN${NC}: logrotate template file" \
      "${BLUE}${logrotate_template_file}${NC}" \
      "not found, nginx logs won't be rotated"
  fi
}

setup_crontab_and_run_cmd() {
  if [ -f "${crontab_file}" ]; then
    echo -e "(Re-)setting crontab to:"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat "${crontab_file}"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # If we assign the crontab to the 'sender' user (crontab -u ...) it won't work, 
    # as sender dosn't have perms on /dev/stdout
    # Instead, consider using supercronic - https://github.com/aptible/supercronic/ so that
    # we can run as non-root
    /usr/bin/crontab "${crontab_file}"

    # start crond as root
    echo -e "Starting crond in the background"

    /usr/sbin/crond -l 8 && \
      echo -e "Starting CMD: [" "$@" "]" && \
      exec "$@"
  else
    echo -e "${RED}WARN${NC}: crontab file ${BLUE}${crontab_file}${NC} not" \
      "found, can't start cron, nginx logs won't be rotated"
    # Now run the CMD
    echo -e "Starting CMD: [" "$@" "]"
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

  setup_colours
  create_nginx_conf

  echo -e "Ensuring directories"
  # Ensure we have the sub-directories in our /nginx/logs/ volume
  mkdir -p "${logs_dir}/access"
  mkdir -p "${logs_dir}/app"

  # shellcheck disable=SC1090
  . "${base_dir}/add_container_identity_headers.sh" "${log_sender_headers_file}"

  setup_logrotate
  setup_crontab_and_run_cmd "$@"
}

main "$@"

# vim: set shiftwidth=2 tabstop=2:
