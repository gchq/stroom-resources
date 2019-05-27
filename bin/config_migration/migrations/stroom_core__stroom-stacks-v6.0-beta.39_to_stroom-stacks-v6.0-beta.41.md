# Differences between `stroom-stacks-v6.0-beta.39` and `stroom-stacks-v6.0-beta.41`

## Added

```bash
```

## Removed

```bash
```

## Changed default values

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.39` env file

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.41` env file

```bash
```
## Changes to the volumes directory

* auth-ui/
    * certs/
    * conf/
* nginx/
    * certs/
    * conf/
    * html/
* stroom-all-dbs/
    * conf/
    * init/
        * 001_create_databases.sql.template - **MODIFIED** (see below)
* stroom-log-sender/
    * certs/
    * conf/
* stroom-proxy-local/
    * certs/

### Diff for 001_create_databases.sql.template

From: `./build/stroom-stacks-v6.0-beta.39/stroom_core/volumes/stroom-all-dbs/init/001_create_databases.sql.template`

To:   `./build/stroom-stacks-v6.0-beta.41/stroom_core/volumes/stroom-all-dbs/init/001_create_databases.sql.template`

```diff
--- 
+++ 
@@ -3,37 +3,37 @@
 -- The <<<MY_TAG>>> tags will be substituted for the value of the
 -- environment variable with the same name (e.g. MY_TAG)
 
-CREATE DATABASE IF NOT EXISTS annotations;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_ANNOTATIONS_DB_NAME>>>;
 CREATE USER "<<<STROOM_ANNOTATIONS_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_ANNOTATIONS_DB_PASSWORD>>>";
-GRANT ALL ON annotations.* TO "<<<STROOM_ANNOTATIONS_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_ANNOTATIONS_DB_NAME>>>.* TO "<<<STROOM_ANNOTATIONS_DB_USERNAME>>>"@"%";
 
-CREATE DATABASE IF NOT EXISTS auth;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_AUTH_DB_NAME>>>;
 CREATE USER "<<<STROOM_AUTH_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_AUTH_DB_PASSWORD>>>";
-GRANT ALL ON auth.* TO "<<<STROOM_AUTH_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_AUTH_DB_NAME>>>.* TO "<<<STROOM_AUTH_DB_USERNAME>>>"@"%";
 
-CREATE DATABASE IF NOT EXISTS config;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_CONFIG_DB_NAME>>>;
 CREATE USER "<<<STROOM_CONFIG_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_CONFIG_DB_PASSWORD>>>";
-GRANT ALL ON config.* TO "<<<STROOM_CONFIG_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_CONFIG_DB_NAME>>>.* TO "<<<STROOM_CONFIG_DB_USERNAME>>>"@"%";
 
-CREATE DATABASE IF NOT EXISTS datameta;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_DATAMETA_DB_NAME>>>;
 CREATE USER "<<<STROOM_DATAMETA_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_DATAMETA_DB_PASSWORD>>>";
-GRANT ALL ON datameta.* TO "<<<STROOM_DATAMETA_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_DATAMETA_DB_NAME>>>.* TO "<<<STROOM_DATAMETA_DB_USERNAME>>>"@"%";
 
-CREATE DATABASE IF NOT EXISTS explorer;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_EXPLORER_DB_NAME>>>;
 CREATE USER "<<<STROOM_EXPLORER_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_EXPLORER_DB_PASSWORD>>>";
-GRANT ALL ON explorer.* TO "<<<STROOM_EXPLORER_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_EXPLORER_DB_NAME>>>.* TO "<<<STROOM_EXPLORER_DB_USERNAME>>>"@"%";
 
-CREATE DATABASE IF NOT EXISTS process;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_PROCESS_DB_NAME>>>;
 CREATE USER "<<<STROOM_PROCESS_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_PROCESS_DB_PASSWORD>>>";
-GRANT ALL ON process.* TO "<<<STROOM_PROCESS_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_PROCESS_DB_NAME>>>.* TO "<<<STROOM_PROCESS_DB_USERNAME>>>"@"%";
 
-CREATE DATABASE IF NOT EXISTS stats;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_STATS_DB_NAME>>>;
 CREATE USER "<<<STROOM_STATS_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_STATS_DB_PASSWORD>>>";
-GRANT ALL ON stats.* TO "<<<STROOM_STATS_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_STATS_DB_NAME>>>.* TO "<<<STROOM_STATS_DB_USERNAME>>>"@"%";
 
-CREATE DATABASE IF NOT EXISTS stroom;
+CREATE DATABASE IF NOT EXISTS <<<STROOM_DB_NAME>>>;
 CREATE USER "<<<STROOM_DB_USERNAME>>>"@"%" IDENTIFIED BY "<<<STROOM_DB_PASSWORD>>>";
-GRANT ALL ON stroom.* TO "<<<STROOM_DB_USERNAME>>>"@"%";
+GRANT ALL ON <<<STROOM_DB_NAME>>>.* TO "<<<STROOM_DB_USERNAME>>>"@"%";
 
 SELECT 'Dumping list of databases' AS '';
 SELECT '---------------------------------------' AS '';
```
