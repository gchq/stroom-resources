# Differences between `stroom-stacks-v6.0.7` and `stroom-stacks-v6.0.9`

## Environment variable changes

### Added

```bash
```

### Removed

```bash
```

### Changed default values

```bash
```

### Variables that occur more than once within the `stroom-stacks-v6.0.7` env file

```bash
```

### Variables that occur more than once within the `stroom-stacks-v6.0.9` env file

```bash
```
## Changes to the volumes directory (the directory tree will always be displayed)

* nginx/
    * certs/
    * conf/
    * html/
* stroom/
    * config/
* stroom-all-dbs/
    * conf/
    * init/
* stroom-auth-service/
    * config/
* stroom-auth-ui/
    * certs/
    * conf/
* stroom-log-sender/
    * certs/
    * conf/
* stroom-proxy-local/
    * certs/
    * config/

Changed config file count: **0**

## Changes to the Docker image versions

```diff
--- ALL_SERVICES.txt
+++ ALL_SERVICES.txt
@@ -2 +2 @@
-stroom|gchq/stroom:v6.0.7
+stroom|gchq/stroom:v6.0.9
@@ -7 +7 @@
-stroom-proxy-local|gchq/stroom-proxy:v6.0.7
+stroom-proxy-local|gchq/stroom-proxy:v6.0.9
```

<!-- vim: set filetype=markdown -->