# Differences between `stroom-stacks-v6.0-beta.34` and `stroom-stacks-v6.0-beta.35`

## Added

```bash
```

## Removed

```bash
```

## Changed default values

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.34` env file

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.35` env file

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

From: `./build/stroom-stacks-v6.0-beta.34/stroom_core/volumes/stroom-all-dbs/init/001_create_databases.sql.template`

To:   `./build/stroom-stacks-v6.0-beta.35/stroom_core/volumes/stroom-all-dbs/init/001_create_databases.sql.template`

```diff
--- 
+++ 
@@ -42,3 +42,5 @@
 SELECT 'Dumping list of users' AS '';
 SELECT '---------------------------------------' AS '';
 SELECT User AS 'USER', Host AS 'HOST' FROM mysql.user;
+
+-- vim: set filetype=sql:
```
