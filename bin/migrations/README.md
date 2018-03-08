# Database Migration Scripts

This directory contains a set of scripts that can be used to run repeatable migrations of the stroom database. The intention is to provide a safe means of testing migrations on 'live' databases without affecting the running instances.

The process is as follows:

* Take a mysqldump of the database you wish to migrate, this will generate a large SQL file
* Run up a new mysql container (using Docker). It will be called `stroom-migration-test-db`
* Feed the DB dump into this migration test mysql container, thereby creating a complete copy of the original database that can be safely played with.
* Run the Flyway migration on the migration db using the Stroom fat jar 
* If you get `Successfully applied XX migrations to schema 'stroom'` then you may do a celebratory dance/high five with your nearest neighbour.

# The Scripts

The scripts in this folder will assist you with this process. They are split as follows:

## load_database_dump.sh

This takes a MySQL dump and creates the `stroom-migration-test-db` container, then feeds the dump in to the container. This script gives the developer a one line process to stand up the database ready for experimentation. This script will delete any existing `stroom-migration-test-db` container before creating a fresh one.

## flyway.sh

This takes the stroom fat jar, and a flyway command to run (migrate|info|clean...etc etc) and connects to the `stroom-migration-test-db` to attempt that command. If this fails for any reason, then you may need to run load_database_dump.sh again to get to a known state.

# Things to Watch out for

In using these scripts, there were a few traps we hit upon. Rather than complicate our scripts by 'handling' all these possible conditions, we will simply document them here and the developer can manually hack the files if necessary.

## Lower Case Table Names
Some old stroom installations used lower case table names, if you have a db dump from one of these, then it will be necessary to set a SQL system variable on the stroom-migration-test-db. Add the following to the mysql run command:

`--lower_case_table_names=1`

## Database Dumps that do not specify db
The scripts assume that the database dumps will name the database to create and use. If this is not the case then it will be necessary to manually add the following to the dump SQL file.

`CREATE DATABASE stroom; USE stroom;`



