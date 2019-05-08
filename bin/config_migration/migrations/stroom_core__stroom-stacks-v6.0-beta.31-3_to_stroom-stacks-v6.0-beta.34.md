# Differences between `stroom-stacks-v6.0-beta.31-3` and `stroom-stacks-v6.0-beta.34`

## Added

```bash
STROOM_UI_HOST=$HOST_IP
```

## Removed

```bash
DOCKER_HOST_HOSTNAME=UNKNOWN
DOCKER_HOST_IP=UNKNOWN
NGINX_HOST=$HOST_IP
STROOM_AUTHORISATION_SERVICE_HOST=$HOST_IP
STROOM_AUTH_EMAIL_RESET_URL=http://$HOST_IP:5000/resetPassword/?token=%s
STROOM_AUTH_STROOM_UI=http://$HOST_IP:8099
STROOM_AUTH_UI_URL=$HOST_IP:9443
STROOM_UI_URL=http://localhost:5001/
```

## Changed default values

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.31-3` env file

```bash
```

## Variables that occur more than once within the `stroom-stacks-v6.0-beta.34` env file

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
    * html/ - **ADDED**
* stroom-all-dbs/
    * conf/
    * init/
* stroom-log-sender/
    * certs/
    * conf/
* stroom-proxy-local/
    * certs/

### Diff for nginx.conf.template

From: `./build/stroom-stacks-v6.0-beta.31-3/stroom_core/volumes/nginx/conf/nginx.conf.template`

To:   `./build/stroom-stacks-v6.0-beta.34/stroom_core/volumes/nginx/conf/nginx.conf.template`

```diff
--- 
+++ 
@@ -52,23 +52,23 @@
 
     upstream auth_service_upstream_sticky {
         ip_hash; # Upstream determined by a hash of the clients IP address -- effectively enabling sticky sessions
-        server ${AUTH_SERVICE_HOST}:${AUTH_SERVICE_PORT};
+        server <<<AUTH_SERVICE_HOST>>>:<<<AUTH_SERVICE_PORT>>>;
         # Can add other servers below
     }
 
     upstream stroom_upstream_sticky {
         ip_hash; # Upstream determined by a hash of the clients IP address -- effectively enabling sticky sessions
-        server ${STROOM_HOST}:${STROOM_PORT};
+        server <<<STROOM_HOST>>>:<<<STROOM_PORT>>>;
         # Can add other servers below
     }
 
     upstream stroom_upstream {
-        server ${STROOM_HOST}:${STROOM_PORT};
+        server <<<STROOM_HOST>>>:<<<STROOM_PORT>>>;
         # Can add other servers below
     }
 
     upstream stroom_proxy_upstream {
-        server ${STROOM_PROXY_HOST}:${STROOM_PROXY_PORT};
+        server <<<STROOM_PROXY_HOST>>>:<<<STROOM_PROXY_PORT>>>;
         # Can add other servers below
     }
 
@@ -83,7 +83,7 @@
     }
     server {
         listen 46011;
-        return 302 https://${AUTH_UI_URL}/userSearch/;
+        return 302 https://<<<AUTH_UI_URL>>>/userSearch/;
     }
 
     ### LOGIN ###
@@ -93,7 +93,7 @@
     }
     server {
         listen 46021;
-        return 302 https://${AUTH_UI_URL}/login/;
+        return 302 https://<<<AUTH_UI_URL>>>/login/;
     }
 
     ### TOKENS ###
@@ -103,7 +103,7 @@
     }
     server {
         listen 46031;
-        return 302 https://${AUTH_UI_URL}/tokens/;
+        return 302 https://<<<AUTH_UI_URL>>>/tokens/;
     }
 
     ### CHANGEPASSWORD ###
@@ -113,7 +113,7 @@
     }
     server {
         listen 46041;
-        return 302 https://${AUTH_UI_URL}/changepassword/;
+        return 302 https://<<<AUTH_UI_URL>>>/changepassword/;
     }
 
     ### AUTHUI ###
@@ -123,7 +123,7 @@
     }
     server {
         listen 46051;
-        return 302 https://${AUTH_UI_URL}/;
+        return 302 https://<<<AUTH_UI_URL>>>/;
     }
 
     ### ANNOTATIONS ###
@@ -133,7 +133,7 @@
     }
     server {
         listen 46061;
-        return 302 ${ANNOTATIONS_UI_URL}/;
+        return 302 <<<ANNOTATIONS_UI_URL>>>/;
     }
 
     ### QUERY-ELASTIC ###
@@ -143,7 +143,7 @@
     }
     server {
         listen 46071;
-        return 302 ${QUERY_ELASTIC_UI_URL}/;
+        return 302 <<<QUERY_ELASTIC_UI_URL>>>/;
     }
 
 
@@ -151,21 +151,21 @@
 
     server {
         #rewrite_log    on;
-	#log_not_found  on;
+        #log_not_found  on;
         #log_subrequest on;
 
-        root /usr/share/nginx/html;
+        root <<<NGINX_HTML_ROOT_PATH>>>;
 
         listen                      80;
         listen                      443 ssl;
-        server_name                 ${NGINX_ADVERTISED_HOST} localhost;
+        server_name                 <<<NGINX_ADVERTISED_HOST>>> localhost;
 
         # The server's public certificate
-        ssl_certificate             /stroom-nginx/certs/${NGINX_SSL_CERTIFICATE};
+        ssl_certificate             /stroom-nginx/certs/<<<NGINX_SSL_CERTIFICATE>>>;
         # The server's private key
-        ssl_certificate_key         /stroom-nginx/certs/${NGINX_SSL_CERTIFICATE_KEY};
+        ssl_certificate_key         /stroom-nginx/certs/<<<NGINX_SSL_CERTIFICATE_KEY>>>;
         # The public CA cert for verifying client certs
-        ssl_client_certificate      /stroom-nginx/certs/${NGINX_SSL_CLIENT_CERTIFICATE};
+        ssl_client_certificate      /stroom-nginx/certs/<<<NGINX_SSL_CLIENT_CERTIFICATE>>>;
 
         # These two need to be on otherwise we won't be able to extract the DN or the cert
         # In order to capture the DN in the headers/logs, ssl_client_verify needs to be set
@@ -173,7 +173,7 @@
         # a cert and use it if it does. Nginx doedsn't currently (without using multiple server 
         # blocks) have a way to set ssl_client_verify at the 'location' level which would 
         # allow us to selectively turn it on.
-        ssl_verify_client           ${NGINX_SSL_VERIFY_CLIENT};
+        ssl_verify_client           <<<NGINX_SSL_VERIFY_CLIENT>>>;
         ssl_verify_depth            10;
 
         # These set the timeouts - the unit is seconds
@@ -186,7 +186,7 @@
         client_max_body_size        0;
 
         # Set the amount of memory used to buffer client bodies before using temporary files
-        client_body_buffer_size     ${NGINX_CLIENT_BODY_BUFFER_SIZE};
+        client_body_buffer_size     <<<NGINX_CLIENT_BODY_BUFFER_SIZE>>>;
 
         # If this were on NGINX would buffer all client request bodies. This includes any huge
         # files sent to datafeed. Turning this off means all requests are immediately sent to
@@ -217,7 +217,7 @@
             # From https://enable-cors.org/server_nginx.html
             if ($request_method = 'OPTIONS') {
                 add_header 'Access-Control-Allow-Credentials' true;
-                add_header 'Access-Control-Allow-Origin'      ${AUTH_UI_URL};
+                add_header 'Access-Control-Allow-Origin'      <<<AUTH_UI_URL>>>;
                 add_header 'Access-Control-Allow-Methods'     'GET, POST, OPTIONS';
                 #
                 # Custom headers and headers various browsers *should* be OK with but aren't
@@ -233,14 +233,14 @@
             }
             if ($request_method = 'POST') {
                 add_header 'Access-Control-Allow-Credentials' true;
-                add_header 'Access-Control-Allow-Origin'      ${AUTH_UI_URL};
+                add_header 'Access-Control-Allow-Origin'      <<<AUTH_UI_URL>>>;
                 add_header 'Access-Control-Allow-Methods'     'GET, POST, OPTIONS';
                 add_header 'Access-Control-Allow-Headers'     'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range';
                 add_header 'Access-Control-Expose-Headers'    'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range';
             }
             if ($request_method = 'GET') {
                 add_header 'Access-Control-Allow-Credentials' true;
-                add_header 'Access-Control-Allow-Origin'      ${AUTH_UI_URL};
+                add_header 'Access-Control-Allow-Origin'      <<<AUTH_UI_URL>>>;
                 add_header 'Access-Control-Allow-Methods'     'GET, POST, OPTIONS';
                 add_header 'Access-Control-Allow-Headers'     'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range';
                 add_header 'Access-Control-Expose-Headers'    'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range';
@@ -305,7 +305,7 @@
 
         location /annotationsService/ {
             proxy_ssl_server_name      on;
-            proxy_pass                 http://${NGINX_ADVERTISED_HOST}:8199/;
+            proxy_pass                 http://<<<NGINX_ADVERTISED_HOST>>>:8199/;
             proxy_pass_header          Set-Cookie;
             proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_pass_request_body    on;
@@ -353,7 +353,7 @@
         #Stroom-stats query service on stroom-stats
         location /stroomstatsService/ {
             proxy_ssl_server_name      on;
-            proxy_pass                 http://${NGINX_ADVERTISED_HOST}:8086/api/stroom-stats/;
+            proxy_pass                 http://<<<NGINX_ADVERTISED_HOST>>>:8086/api/stroom-stats/;
             proxy_pass_header          Set-Cookie;
             proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_pass_request_body    on;
@@ -362,7 +362,7 @@
 
         location /queryElasticService/ {
             proxy_ssl_server_name      on;
-            proxy_pass                 http://${NGINX_ADVERTISED_HOST}:8299/;
+            proxy_pass                 http://<<<NGINX_ADVERTISED_HOST>>>:8299/;
             proxy_pass_header          Set-Cookie;
             proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_pass_request_body    on;
@@ -466,7 +466,7 @@
 
         # This is an exact match that directs '/stroom' to the Stroom UI...
         location ~ /stroom$ {
-             return 302 https://${NGINX_ADVERTISED_HOST}/stroom/ui;
+             return 302 https://<<<NGINX_ADVERTISED_HOST>>>/stroom/ui;
         }
 
         location ~ .*/clustercall.rpc$ {
@@ -476,7 +476,7 @@
         # ... and everything else gets reverse-proxied to stroom.
         location /stroom {
             proxy_ssl_server_name      on;
-            proxy_pass                 http://${STROOM_HOST}:${STROOM_PORT}/stroom;
+            proxy_pass                 http://<<<STROOM_HOST>>>:<<<STROOM_PORT>>>/stroom;
             proxy_pass_header          Set-Cookie;
             proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_pass_request_body    on;
```
