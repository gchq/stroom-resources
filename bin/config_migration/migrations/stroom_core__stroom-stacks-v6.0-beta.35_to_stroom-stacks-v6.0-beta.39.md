# Differences between `stroom-stacks-v6.0-beta.35` and `stroom-stacks-v6.0-beta.39`

## Added

```bash
STROOM_DOCKER_REPO=gchq/stroom
STROOM_PROXY_LOCAL_FEED_STATUS_API_KEY=eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6InN0cm9vbSIsInNpZCI6bnVsbH0.k0Ssb43GCdTunAMeM26fIulYKNUuPUaJJk6GxDmzCPb7kVPwEtdfBSrtwazfEFM97dnmvURkLqs-DAZTXhhf-0VqQx4hkwcCHf83eVptWTy-lufIhQo6FCM223c9ONIhl6CPqknWh9Bo3vFNrNJoKz5Zw2T_iCcQhi2WGjd_tjTG7VbibTIpH3lPQDw1IBD2nMsEqACJSk3IaFe0GYcrAEMwsjj3sjAwByMbj5DJvo_DJbAuzUwS5IVpASEENen5Xd3wALLirrraUfED1OY0G56Ttcwl3uQ2s-grZXBM4JCiIurlWR5iNtNwoPUsZsyMju4FMSXt3Ur1NIpD7XKJlg
STROOM_PROXY_LOCAL_FEED_STATUS_URL=http://$NGINX_ADVERTISED_HOST/feedStatusService/v1
STROOM_PROXY_LOCAL_FORWARDING_ENABLED=false
STROOM_PROXY_LOCAL_JERSEY_VERIFY_HOSTNAME=false
STROOM_PROXY_LOCAL_STORING_ENABLED=true
STROOM_SECURITY_API_TOKEN=eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6InN0cm9vbSIsInNpZCI6bnVsbH0.k0Ssb43GCdTunAMeM26fIulYKNUuPUaJJk6GxDmzCPb7kVPwEtdfBSrtwazfEFM97dnmvURkLqs-DAZTXhhf-0VqQx4hkwcCHf83eVptWTy-lufIhQo6FCM223c9ONIhl6CPqknWh9Bo3vFNrNJoKz5Zw2T_iCcQhi2WGjd_tjTG7VbibTIpH3lPQDw1IBD2nMsEqACJSk3IaFe0GYcrAEMwsjj3sjAwByMbj5DJvo_DJbAuzUwS5IVpASEENen5Xd3wALLirrraUfED1OY0G56Ttcwl3uQ2s-grZXBM4JCiIurlWR5iNtNwoPUsZsyMju4FMSXt3Ur1NIpD7XKJlg
```

## Removed

```bash
STROOM_PROXY_LOCAL_SYNC_API_KEY=
STROOM_PROXY_LOCAL_UPSTREAM_DICTIONARY_URL=http://stroom:8080/api/dictionary/v1
STROOM_PROXY_LOCAL_UPSTREAM_RULE_URL=http://stroom:8080/api/ruleset/v1
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
* stroom-all-dbs/
    * conf/
    * init/
* stroom-log-sender/
    * certs/
    * conf/
* stroom-proxy-local/
    * certs/

### Diff for nginx.conf.template

From: `./build/stroom-stacks-v6.0-beta.35/stroom_core/volumes/nginx/conf/nginx.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.39/stroom_core/volumes/nginx/conf/nginx.conf.template`

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
