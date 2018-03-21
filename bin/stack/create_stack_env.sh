#!/usr/bin/env bash
#
# Takes docker-compose yaml and extracts the possible configurations, 
# including the default values. This can be used to make sure the 
# configuration is always complete.

source lib/shell.sh
source lib/network.sh

create_config() {
    rm -f "$OUTPUT_FILE"
    touch "$OUTPUT_FILE"
    chmod +x "$OUTPUT_FILE"
}

add_params() {
    params=$( \
        # Extracts the params
        grep -Po "(?<=\\$\\{).*?(?=\\})" $INPUT_FILE |
        # Replaces ':-'' with '='
        sed "s/:-/=\"/g" |
        # Adds a closing single quote to the end of the line
        sed "s/$/\"/g" |
        # Adds 'export' to the start of the line
        sed "s/^/export /" | 
        # Add in the stack name
        sed "s/<STACK_NAME>/$STACK_NAME/g" )

    echo "$params" >> "$OUTPUT_FILE"
}

main() {
    readonly local STACK_NAME=$1
    readonly local BUILD_FOLDER='build'
    readonly local WORKING_DIRECTORY="$BUILD_FOLDER/$STACK_NAME"
    readonly local INPUT_FILE="$WORKING_DIRECTORY/$STACK_NAME.yml"
    readonly local OUTPUT_FILE="$WORKING_DIRECTORY/$STACK_NAME.env"

    setup_echo_colours
    create_config
    add_params
    # Sort and de-duplicate param list before we do anything else with the file
    sort -o "$OUTPUT_FILE" -u "$OUTPUT_FILE"
}

main "$@"