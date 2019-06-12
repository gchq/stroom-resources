# Differences between `stroom-stacks-v6.0-beta.41` and `stroom-stacks-v6.0-beta.42`

## Added

```bash
```

## Removed

```bash
```

## Changed default values

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.41` env file

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.42` env file

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

From: `./build/stroom-stacks-v6.0-beta.41/stroom_services/volumes/nginx/conf/nginx.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.42/stroom_services/volumes/nginx/conf/nginx.conf.template`

```diff
--- 
+++ 
@@ -396,6 +396,8 @@
             proxy_set_header           X-SSL-Client-Verify  $ssl_client_verify;
             proxy_set_header           X-SSL-Protocol       $ssl_protocol;
             proxy_set_header           X-Forwarded-For      $proxy_add_x_forwarded_for;
+            # Reset host header to the host the client put in their url, else you get stroom_upstream
+            proxy_set_header           Host                 $host;
             proxy_pass_request_body    on;
             proxy_pass_request_headers on;
         }
@@ -413,6 +415,8 @@
             proxy_set_header           X-SSL-Client-Verify  $ssl_client_verify;
             proxy_set_header           X-SSL-Protocol       $ssl_protocol;
             proxy_set_header           X-Forwarded-For      $proxy_add_x_forwarded_for;
+            # Reset host header to the host the client put in their url, else you get stroom_upstream
+            proxy_set_header           Host                 $host;
             proxy_pass_request_body    on;
             proxy_pass_request_headers on;
         }
@@ -430,6 +434,8 @@
             proxy_set_header           X-SSL-Client-Verify  $ssl_client_verify;
             proxy_set_header           X-SSL-Protocol       $ssl_protocol;
             proxy_set_header           X-Forwarded-For      $proxy_add_x_forwarded_for;
+            # Reset host header to the host the client put in their url, else you get stroom_proxy_upstream
+            proxy_set_header           Host                 $host;
             proxy_pass_request_body    on;
             proxy_pass_request_headers on;
         }
@@ -447,6 +453,8 @@
             proxy_set_header           X-SSL-Client-Verify  $ssl_client_verify;
             proxy_set_header           X-SSL-Protocol       $ssl_protocol;
             proxy_set_header           X-Forwarded-For      $proxy_add_x_forwarded_for;
+            # Reset host header to the host the client put in their url, else you get stroom_proxy_upstream
+            proxy_set_header           Host                 $host;
             proxy_pass_request_body    on;
             proxy_pass_request_headers on;
         }
```
<!-- vim: set filetype=markdown -->