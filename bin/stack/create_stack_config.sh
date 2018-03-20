#!/usr/bin/env bash
#
# Takes docker-compose yaml and extracts the possible configurations, 
# including the default values. This can be used to make sure the 
# configuration is always complete.

source common.sh

create_sh() {
    echo '#!/usr/bin/env bash' > "$OUTPUT_FILE"
    echo '#' >> "$OUTPUT_FILE"
    echo '# Starts a stack, providing the following configuration' >> "$OUTPUT_FILE"
    echo '' >> "$OUTPUT_FILE"
    chmod +x "$OUTPUT_FILE"
}

add_params() {
    params=$( \
        # Extracts the params
        grep -Po "(?<=\\$\\{).*?(?=\\})" $INPUT_FILE |
        # Replaces ':-'' with '='
        sed "s/:-/='/g" |
        # Adds a closing single quote to the end of the line
        sed "s/$/'/g" |
        # Adds 'export' to the start of the line
        sed "s/^/export /")
    echo "$params" >> "$OUTPUT_FILE"
}

add_docker_command() {
    echo "" >> "$OUTPUT_FILE"
    echo "docker-compose -f stack.yml up -d" >> "$OUTPUT_FILE"
}

main() {
    readonly local INPUT_FILE=$1
    readonly local OUTPUT_FILE=$2

    setup_echo_colours
    create_sh
    add_params
    add_docker_command
}

main "$@"