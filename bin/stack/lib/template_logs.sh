#!/usr/bin/env bash
#
# Shows the stacks logs

cmd_help_msg="Tails the logs for the specified services or all services if none are supplied."
cmd_help_options="  -n N Set the number of previous lines to display per service (or 'all'), default is 5."
line_count_per_service="5"
extra_compose_args=()

# We shouldn't use a lib function (e.g. in shell_utils.sh) because it will
# give the directory relative to the lib script, not this script.
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DIR"/lib/shell_utils.sh
source "$DIR"/lib/stroom_utils.sh

main() {

  # leading colon means silent error reporting by getopts
  while getopts ":mhn:" arg; do
    case $arg in
      h )  
        show_default_services_usage "${cmd_help_msg}" "${cmd_help_options}"
        exit 0
        ;;
      m )  
        # shellcheck disable=SC2034
        MONOCHROME=true 
        extra_compose_args+=( "--no-color" )
        ;;
      n )  
        line_count_per_service="${OPTARG}"
        ;;
    esac
  done
  shift $((OPTIND-1)) # remove parsed options and args from $@ list

  local running_service_count
  running_service_count="$(
    docker ps \
      --filter "label=stack_name=<STACK_NAME>" \
      --format  "{{.ID}}" \
      | wc -l
  )"

  if [ "${running_service_count}" -eq 0 ]; then
    die "${RED}Error${NC}: No services are running."
  fi

  for requested_service in "${@}"; do
    if ! is_service_in_stack "${requested_service}"; then
      die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not in the stack."
    fi
    if ! is_container_running "${requested_service}"; then
      die "${RED}Error${NC}: Service ${BLUE}${requested_service}${NC} is not running."
    fi
  done
  extra_compose_args+=( "${@}" )

  #echo "Remaining args: [${*}]"

  # Has to be called after MONOCHROME has had a chance to be set
  setup_echo_colours

  if [ "${line_count_per_service}" == "all" ]; then
    echo -e "${GREEN}Tailing the logs from the first entry onwards${NC}"
  else
    echo -e "${GREEN}Tailing the logs from the last ${line_count_per_service} entries onwards${NC}"
  fi

  # shellcheck disable=SC2094
  docker-compose \
    --project-name <STACK_NAME> \
    -f "$DIR"/config/<STACK_NAME>.yml \
    logs \
    -f \
    --tail="${line_count_per_service}" \
    "${extra_compose_args[@]}"
}

main "${@}"
