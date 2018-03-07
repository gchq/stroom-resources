#!/usr/bin/env bash

#Get the dir that this script lives in, no matter where it is called from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $SCRIPT_DIR/../utilities.sh

determineHostAddress

SQL_DUMP_FILE=$1
STROOM_FAT_JAR=$2
DATABASE_NAME=$3

# Location of migration
WORKING_DIR=~/.stroom/migrationTest/jars
TEMP_DB_ROOT_PW=my-secret-pw

echo "Deleting any existing migration MySQL DB"
docker rm -f stroom-migration-test-db

echo "Starting a Docker MySQL instance to test migration of ${DATABASE_NAME} with  ${SQL_DUMP_FILE} using Stroom Fat Jar ${STROOM_FAT_JAR}"

echo "Starting a new MySQL container for testing migration"
docker run -p 5506:3306 --name stroom-migration-test-db --health-cmd='mysqladmin ping --silent' --health-interval=10s -e MYSQL_ROOT_PASSWORD=${TEMP_DB_ROOT_PW} -d mysql:5.6

waitContainer stroom-migration-test-db
echo "Database ready"

echo "Uploading the SQL Dump file into the Migration MySQL DB"
cat ${SQL_DUMP_FILE} | docker exec -i stroom-migration-test-db mysql -u"root" -p"${TEMP_DB_ROOT_PW}"

echo "SQL dump loaded into database in container stroom-migration-test-db"