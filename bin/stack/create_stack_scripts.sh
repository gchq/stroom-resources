#!/usr/bin/env bash
#
# Creates scripts to run stacks

source lib/shell.sh

create_script() {
  local script_name=$1
  local SCRIPT_PATH="$WORKING_DIRECTORY/$script_name.sh"
  sed "s/<STACK_NAME>/$STACK_NAME/g" "$LIB_DIRECTORY/template_$script_name.sh" > "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
}

main() {
    setup_echo_colours

    echo -e "${GREEN}Copying stack management scripts${NC}"
    readonly local BUILD_DIRECTORY='build'
    readonly local STACK_NAME=$1
    readonly local LIB_DIRECTORY='lib'
    readonly local WORKING_DIRECTORY="$BUILD_DIRECTORY/$STACK_NAME"

    create_script ctop
    create_script logs
    create_script remove
    create_script restart
    create_script start
    create_script status
    create_script stop
    create_script stack

}

main "$@"