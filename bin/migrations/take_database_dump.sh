#!/usr/bin/env bash
#
# Use this script to take a SQL dumps from Stroom databases.

# Location of the file used to store private values (db credentials)
readonly CREDENTIALS_FILE=~/.stroom/credentials.sh

# Location of migration
readonly WORKING_DIR=~/.stroom/migrationTest

#Source the temp file to export all our env vars
echo "Running Credentials File ${CREDENTIALS_FILE}"
source ${CREDENTIALS_FILE}

# Clean up any existing working directory
echo "Cleaning up Working Directory $WORKING_DIR"
# rm -rf $WORKING_DIR
mkdir -p $WORKING_DIR

readonly STACK_VERSION=$1

dumpDb() {
    local -r DOCKER_CONTAINER=$1
    local -r DB_NAME=$2
    local -r PORT=$3
    local -r ROOT_PW=$4

    echo "Taking Dump of ${DOCKER_CONTAINER} at port ${PORT} with root pw ${ROOT_PW}"
    docker exec -it ${DOCKER_CONTAINER} mysqldump --databases $DB_NAME -u"root" -p"${ROOT_PW}" | grep -v "Using a password" > $WORKING_DIR/${DOCKER_CONTAINER}_${STACK_VERSION}.sql
}

dumpDb stroom-db stroom 3307 ${STROOM_DB_ROOT_PASSWORD} STACK_VERSION
#dumpDb stroom-stats-db statistics 3308 ${STROOM_STATS_DB_ROOT_PASSWORD}
#dumpDb stroom-auth-db auth 3309 ${STROOM_AUTH_DB_ROOT_PASSWORD}
#dumpDb stroom-annotations-db annotations 3310 ${STROOM_ANNOTATIONS_DB_ROOT_PASSWORD}

echo "Contents of Working Directory"
ls -lrth ${WORKING_DIR}
