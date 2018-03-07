#!/usr/bin/env bash

# Arguments managed using argbash. To re-generate install argbash and run 'argbash flyway_args.m4 -o flyway_args.sh'
source flyway_args.sh

# Get the dir that this script lives in, no matter where it is called from
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $script_dir/../utilities.sh

determineHostAddress # For STROOM_RESOURCES_ADVERTISED_HOST
working_dir=~/.stroom/migrationTest/jars
temp_db_root_pw=my-secret-pw
username=root
password=my-secret-pw
url=jdbc:mysql://${STROOM_RESOURCES_ADVERTISED_HOST}:5506/${_arg_database_name}

echo "Running Flyway with '$_arg_flyway_command'."
java -cp ${_arg_stroom_fat_jar} stroom.db.migration.FlywayHelper $_arg_flyway_command --url=$url --username=$username --password=$password