# Differences between `stroom-stacks-v6.0-beta.35` and `stroom-stacks-v6.0-beta.39`

## Added

```bash
```

## Removed

```bash
```

## Changed default values

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.35` env file

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.39` env file

```bash
```
## Changes to the volumes directory

* auth-ui/
    * certs/
    * conf/
* nginx/
    * certs/
    * conf/
        * nginx.conf.template - **MODIFIED** (see below)
    * html/
* stroom-log-sender/
    * certs/
    * conf/

### Diff for nginx.conf.template

From: `./build/stroom-stacks-v6.0-beta.35/stroom_services/volumes/nginx/conf/nginx.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.39/stroom_services/volumes/nginx/conf/nginx.conf.template`

```diff
--- 
+++ 
@@ -332,18 +332,29 @@
             proxy_pass_request_headers on;
         }
 
-        location /rulesetService/ {
-            proxy_ssl_server_name      on;
-            proxy_pass                 http://stroom_upstream/api/ruleset/;
-            proxy_pass_header          Set-Cookie;
-            proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
-            proxy_pass_request_body    on;
-            proxy_pass_request_headers on;
-        }
-
-        location /dictionaryService/ {
-            proxy_ssl_server_name      on;
-            proxy_pass                 http://stroom_upstream/api/dictionary/;
+# Ruleset functionality not fit for use in v6 so commented out
+#        location /rulesetService/ {
+#            proxy_ssl_server_name      on;
+#            proxy_pass                 http://stroom_upstream/api/ruleset/;
+#            proxy_pass_header          Set-Cookie;
+#            proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
+#            proxy_pass_request_body    on;
+#            proxy_pass_request_headers on;
+#        }
+#
+#        location /dictionaryService/ {
+#            proxy_ssl_server_name      on;
+#            proxy_pass                 http://stroom_upstream/api/dictionary/;
+#            proxy_pass_header          Set-Cookie;
+#            proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
+#            proxy_pass_request_body    on;
+#            proxy_pass_request_headers on;
+#        }
+
+        # Servcie for proxies to check the accept/reject/drop status of a feed
+        location /feedStatusService/ {
+            proxy_ssl_server_name      on;
+            proxy_pass                 http://stroom_upstream/api/feedStatus/;
             proxy_pass_header          Set-Cookie;
             proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_pass_request_body    on;
@@ -464,6 +475,10 @@
 
         ## ROUTING FOR STROOM
 
+        location = / {
+             return 302 https://<<<NGINX_ADVERTISED_HOST>>>/stroom/ui;
+        }
+
         # This is an exact match that directs '/stroom' to the Stroom UI...
         location ~ /stroom$ {
              return 302 https://<<<NGINX_ADVERTISED_HOST>>>/stroom/ui;
@@ -517,3 +532,5 @@
         }
     }
 }
+
+# vim: set filetype=text:
```
