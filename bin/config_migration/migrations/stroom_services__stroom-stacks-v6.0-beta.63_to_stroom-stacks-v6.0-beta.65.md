# Differences between `stroom-stacks-v6.0-beta.63` and `stroom-stacks-v6.0-beta.65`

## Added

```bash
```

## Removed

```bash
```

## Changed default values

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.63` env file

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.65` env file

```bash
```
## Changes to the volumes directory

* nginx/
    * certs/
    * conf/
        * locations.auth.conf.template - **MODIFIED** (see below)
        * locations.proxy.conf.template - **MODIFIED** (see below)
        * locations.stroom.conf.template - **MODIFIED** (see below)
        * upstreams.stroom.conf.template - **MODIFIED** (see below)
    * html/
* stroom-auth-service/
    * config/
* stroom-auth-ui/
    * certs/
    * conf/
* stroom-log-sender/
    * certs/
    * conf/

### Diff for locations.auth.conf.template

From: `./build/stroom-stacks-v6.0-beta.63/stroom_services/volumes/nginx/conf/locations.auth.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/locations.auth.conf.template`

```diff
--- 
+++ 
@@ -7,11 +7,6 @@
 location /api/auth/ {
     include location_defaults.conf;
     proxy_pass http://auth_service_upstream_sticky/;
-}
-
-location /api/ {
-    include location_defaults.conf;
-    proxy_pass http://stroom_upstream/api/;
 }
 
 ##################
@@ -53,4 +48,4 @@
     #   proxy_set_header Connection "upgrade"; 
     # }
 
-    # vim: set filetype=text shiftwidth=4 tabstop=4 expandtab:
+# vim: set filetype=text shiftwidth=4 tabstop=4 expandtab:
```

### Diff for locations.proxy.conf.template

From: `./build/stroom-stacks-v6.0-beta.63/stroom_services/volumes/nginx/conf/locations.proxy.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/locations.proxy.conf.template`

```diff
--- 
+++ 
@@ -16,9 +16,14 @@
     include proxy_location_defaults.conf;
 }
 
-##################
-# ROUTING FOR UI #
-##################
-
+# All REST services
+# e.g. the feed status service that a proxy exposes (and uses stroom or another proxy
+# to service the request)
+# Needs to be /api/proxy/ rather than /api/ to distinguish it from the stroom upstream,
+# thus we can serve the feed status service on both stroom and a local storing proxy.
+location /api/proxy/ {
+    proxy_pass http://stroom_proxy_upstream/api/;
+    include location_defaults.conf;
+}
 
 # vim: set filetype=text shiftwidth=4 tabstop=4 expandtab:
```

### Diff for locations.stroom.conf.template

From: `./build/stroom-stacks-v6.0-beta.63/stroom_services/volumes/nginx/conf/locations.stroom.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/locations.stroom.conf.template`

```diff
--- 
+++ 
@@ -14,6 +14,12 @@
 location = /stroom/datafeeddirect {
     proxy_pass http://stroom_upstream/stroom/datafeed/;
     include proxy_location_defaults.conf;
+}
+
+# All REST services
+location /api/ {
+    proxy_pass http://stroom_upstream/api/;
+    include location_defaults.conf;
 }
 
 ##################
```

### Diff for upstreams.stroom.conf.template

From: `./build/stroom-stacks-v6.0-beta.63/stroom_services/volumes/nginx/conf/upstreams.stroom.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/upstreams.stroom.conf.template`

```diff
--- 
+++ 
@@ -9,5 +9,4 @@
     server <<<STROOM_HOST>>>:<<<STROOM_PORT>>>;
 }
 
-
 # vim: set filetype=text shiftwidth=4 tabstop=4 expandtab:
```
<!-- vim: set filetype=markdown -->