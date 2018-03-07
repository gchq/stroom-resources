#!/usr/bin/env bash
#
# Script to help with running the FlywayHelper in the Stroom fat jar.

# Arguments managed using argbash. To re-generate install argbash and run 'argbash flyway_args.m4 -o flyway_args.sh'
source flyway_args.sh

# Get the dir that this script lives in, no matter where it is called from
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../utilities.sh

determineHostAddress # For STROOM_RESOURCES_ADVERTISED_HOST
readonly URL=jdbc:mysql://${STROOM_RESOURCES_ADVERTISED_HOST}:5506/${_arg_database_name}
readonly USERNAME=root
readonly PASSWORD=my-secret-pw

echo "Running Flyway with '$_arg_flyway_command'."
java -cp ${_arg_stroom_fat_jar} stroom.db.migration.FlywayHelper $_arg_flyway_command --url=$URL --username=$USERNAME --password=$PASSWORD