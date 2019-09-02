# Differences between `stroom-stacks-v6.0-beta.65` and `stroom-stacks-v6.0.7`

## Added

```bash
_IP=$HOST_IP
```

## Removed

```bash
```

## Changed default values

```bash
STROOM_AUTH_DB_HOST has changed from "$HOST_IP" to "$DB_HOST_IP"
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.65` env file

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0.7` env file

```bash
```
## Changes to the volumes directory

* nginx/
    * certs/
    * conf/
        * locations.auth.conf.template - **MODIFIED** (see below)
        * locations.stroom.conf.template - **MODIFIED** (see below)
        * nginx.conf.template - **MODIFIED** (see below)
        * upstreams.proxy.conf.template - **MODIFIED** (see below)
        * locations.dev.conf.template - **ADDED**
        * upstreams.auth.service.conf.template - **ADDED**
        * upstreams.auth.ui.conf.template - **ADDED**
        * upstreams.stroom.processing.conf.template - **ADDED**
        * upstreams.stroom.ui.conf.template - **ADDED**
        upstreams.stroom.conf.template - **REMOVED**
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

From: `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/locations.auth.conf.template`

To:   `./build/stroom-stacks-v6.0.7/stroom_services/volumes/nginx/conf/locations.auth.conf.template`

```diff
--- 
+++ 
@@ -40,12 +40,4 @@
     proxy_pass https://auth_ui_upstream/s;
 }
 
-# The following should catch websocket requests (wss:) but it doesn't seem to work.
-# location / {
-    #   proxy_pass https://auth_ui_upstream/;
-    #   proxy_http_version 1.1;
-    #   proxy_set_header Upgrade $http_upgrade;
-    #   proxy_set_header Connection "upgrade"; 
-    # }
-
 # vim: set filetype=text shiftwidth=4 tabstop=4 expandtab:
```

### Diff for locations.stroom.conf.template

From: `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/locations.stroom.conf.template`

To:   `./build/stroom-stacks-v6.0.7/stroom_services/volumes/nginx/conf/locations.stroom.conf.template`

```diff
--- 
+++ 
@@ -41,7 +41,7 @@
 
 # ... and everything else gets reverse-proxied to stroom.
 location /stroom {
-    proxy_pass http://<<<STROOM_HOST>>>:<<<STROOM_PORT>>>/stroom;
+    proxy_pass http://stroom_upstream_sticky/stroom;
     include location_defaults.conf;
 }
 
```

### Diff for nginx.conf.template

From: `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/nginx.conf.template`

To:   `./build/stroom-stacks-v6.0.7/stroom_services/volumes/nginx/conf/nginx.conf.template`

```diff
--- 
+++ 
@@ -9,18 +9,35 @@
 http {
     # Include generic logging configuration
     include logging.conf;
-     
-    # Include upstreams configuration specific to stroom
-    include upstreams.stroom.conf;
 
-    # Include upstreams configuration specific to auth
-    include upstreams.auth.conf;
+    upstream stroom_upstream_sticky { 
+        ip_hash;
+        include upstreams.stroom.ui.conf;
+    }
 
-    # Include upstreams configuration specific to proxy
-    include upstreams.proxy.conf;
+    upstream stroom_upstream {
+        include upstreams.stroom.processing.conf;
+    }
+
+    upstream auth_service_upstream_sticky {
+        ip_hash;
+        include upstreams.auth.service.conf;
+    }
+
+    upstream auth_ui_upstream {
+        include upstreams.auth.ui.conf;
+    }
+
+    upstream stroom_proxy_upstream { 
+        include upstreams.proxy.conf;
+    }
 
     # Define valid index page filenames
     index index.html index.htm;
+
+    # Necessary where we have long server names, i.e. aws.
+    # Increasing by default because I'm not clear of the downsides?
+    server_names_hash_bucket_size 128;
 
     # Redirect all http traffic to https
     server {
@@ -41,6 +58,11 @@
 
         # Include location configuration specific to proxy
         include locations.proxy.conf;
+
+        # Include location configuration specific to dev.
+        # Should not be included in production deployments.
+        # Supports hot-loading for stroom-ui
+        include locations.dev.conf;
     }
 }
 
```

### Diff for upstreams.proxy.conf.template

From: `./build/stroom-stacks-v6.0-beta.65/stroom_services/volumes/nginx/conf/upstreams.proxy.conf.template`

To:   `./build/stroom-stacks-v6.0.7/stroom_services/volumes/nginx/conf/upstreams.proxy.conf.template`

```diff
--- 
+++ 
@@ -1,8 +1,5 @@
-# Upstream configuration for stroom
-
-upstream stroom_proxy_upstream {
-    server <<<STROOM_PROXY_HOST>>>:<<<STROOM_PROXY_PORT>>>;
-}
+server <<<STROOM_PROXY_HOST>>>:<<<STROOM_PROXY_PORT>>>;
 
 # vim: set filetype=text shiftwidth=4 tabstop=4 expandtab:
 
+
```
<!-- vim: set filetype=markdown -->