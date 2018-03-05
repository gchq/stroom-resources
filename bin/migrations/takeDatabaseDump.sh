#!/usr/bin/env bash

# Location of the file used to store private values (db credentials)
CREDENTIALS_FILE=~/.stroom/credentials.sh

# Location of migration
WORKING_DIR=~/.stroom/migrationTest

#Source the temp file to export all our env vars
echo "Running Credentials File ${CREDENTIALS_FILE}"
source ${CREDENTIALS_FILE}

# Clean up any existing working directory
echo "Cleaning up Working Directory $WORKING_DIR"
rm -rf $WORKING_DIR
mkdir $WORKING_DIR

dumpDb() {
    local dockerContainer=$1
    local dbName=$2
    local port=$3
    local rootPw=$4

    echo "Taking Dump of ${dockerContainer} at port ${port} with root pw ${rootPw}"
    docker exec -it ${dockerContainer} mysqldump --databases $dbName -u"root" -p"${rootPw}" | grep -v "Using a password" > $WORKING_DIR/${dockerContainer}.sql
}

dumpDb stroom-db stroom 3307 ${STROOM_DB_ROOT_PASSWORD}
dumpDb stroom-stats-db statistics 3308 ${STROOM_STATS_DB_ROOT_PASSWORD}
#dumpDb stroom-auth-db auth 3309 ${STROOM_AUTH_DB_ROOT_PASSWORD}
#dumpDb stroom-annotations-db annotations 3310 ${STROOM_ANNOTATIONS_DB_ROOT_PASSWORD}

echo "Contents of Working Directory"
ls -lrth ${WORKING_DIR}