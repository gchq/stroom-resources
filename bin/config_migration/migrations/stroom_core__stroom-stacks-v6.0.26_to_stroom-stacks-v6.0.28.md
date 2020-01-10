# Differences between `stroom-stacks-v6.0.26` and `stroom-stacks-v6.0.28`

## Environment variable changes

### Added

```bash
DB_HOST_IP=$HOST_IP
NGINX_SSL_CA_CERTIFICATE=ca.pem.crt
```

### Removed

```bash
NGINX_SSL_CLIENT_CERTIFICATE=ca.pem.crt
_IP=$HOST_IP
```

### Changed default values

```bash
STROOM_PROXY_LOCAL_FEED_STATUS_API_KEY has changed from "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6InN0cm9vbSIsInNpZCI6bnVsbH0.k0Ssb43GCdTunAMeM26fIulYKNUuPUaJJk6GxDmzCPb7kVPwEtdfBSrtwazfEFM97dnmvURkLqs-DAZTXhhf-0VqQx4hkwcCHf83eVptWTy-lufIhQo6FCM223c9ONIhl6CPqknWh9Bo3vFNrNJoKz5Zw2T_iCcQhi2WGjd_tjTG7VbibTIpH3lPQDw1IBD2nMsEqACJSk3IaFe0GYcrAEMwsjj3sjAwByMbj5DJvo_DJbAuzUwS5IVpASEENen5Xd3wALLirrraUfED1OY0G56Ttcwl3uQ2s-grZXBM4JCiIurlWR5iNtNwoPUsZsyMju4FMSXt3Ur1NIpD7XKJlg" to "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6InN0cm9vbSIsImF1ZCI6IlBabkpyOGtIUktxbmxKUlFUaFNJIn0.qT5jdPWBpN9me0L3OqUT0VFT2mvVX9mCp0gPFyTVg8DkFTPLLYIuXjOslvrllJDBbqefEtqS9OwQs3RmRnZxror676stTP6JHN76YqJWj2yJYyJGuggbXjZnfTiZGO3SOxl5FP4nmRRvPxA3XqV9kippKBpHfqm5RuTpFTU8uses2iaHFm7lY4zXmKDmwVizXybBQBtpxrBNQkeQjQyg7UFkpsRO8-PmIdbTldRhGlud5VpntwI1_ahwOzK-einUJQOWrcOBmXAMPRYBI6tSLT1xS_c5XpFX1Rxoj3FGjI-Myqp_2Nt_lZuQ3h-0Qh8WkZMnWQ76G7CKawXzRAwd7Q"
STROOM_SECURITY_API_TOKEN has changed from "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6InN0cm9vbSIsInNpZCI6bnVsbH0.k0Ssb43GCdTunAMeM26fIulYKNUuPUaJJk6GxDmzCPb7kVPwEtdfBSrtwazfEFM97dnmvURkLqs-DAZTXhhf-0VqQx4hkwcCHf83eVptWTy-lufIhQo6FCM223c9ONIhl6CPqknWh9Bo3vFNrNJoKz5Zw2T_iCcQhi2WGjd_tjTG7VbibTIpH3lPQDw1IBD2nMsEqACJSk3IaFe0GYcrAEMwsjj3sjAwByMbj5DJvo_DJbAuzUwS5IVpASEENen5Xd3wALLirrraUfED1OY0G56Ttcwl3uQ2s-grZXBM4JCiIurlWR5iNtNwoPUsZsyMju4FMSXt3Ur1NIpD7XKJlg" to "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6InN0cm9vbSIsImF1ZCI6IlBabkpyOGtIUktxbmxKUlFUaFNJIn0.qT5jdPWBpN9me0L3OqUT0VFT2mvVX9mCp0gPFyTVg8DkFTPLLYIuXjOslvrllJDBbqefEtqS9OwQs3RmRnZxror676stTP6JHN76YqJWj2yJYyJGuggbXjZnfTiZGO3SOxl5FP4nmRRvPxA3XqV9kippKBpHfqm5RuTpFTU8uses2iaHFm7lY4zXmKDmwVizXybBQBtpxrBNQkeQjQyg7UFkpsRO8-PmIdbTldRhGlud5VpntwI1_ahwOzK-einUJQOWrcOBmXAMPRYBI6tSLT1xS_c5XpFX1Rxoj3FGjI-Myqp_2Nt_lZuQ3h-0Qh8WkZMnWQ76G7CKawXzRAwd7Q"
```

### Variables that occur more than once within the `stroom-stacks-v6.0.26` env file

```bash
```

### Variables that occur more than once within the `stroom-stacks-v6.0.28` env file

```bash
```
## Changes to the volumes directory (the directory tree will always be displayed)

* nginx/
    * certs/
    * conf/
        * nginx.conf.template - **MODIFIED** (see below)
        * server.conf.template - **MODIFIED** (see below)
        locations.dev.conf.template - **REMOVED**
    * html/
* stroom/
    * config/
* stroom-all-dbs/
    * conf/
    * init/
* stroom-auth-service/
    * config/
        * config.yml - **MODIFIED** (see below)
* stroom-auth-ui/
    * certs/
    * conf/
        * nginx.conf.template - **MODIFIED** (see below)
* stroom-log-sender/
    * certs/
    * conf/
        * crontab.env - **MODIFIED** (see below)
        * crontab.txt - **MODIFIED** (see below)
* stroom-proxy-local/
    * certs/
    * config/

Changed config file count in volumes directory: **6**

### Diff for nginx.conf.template

From: `./build/stroom-stacks-v6.0.26/stroom_core/volumes/nginx/conf/nginx.conf.template`

To:   `./build/stroom-stacks-v6.0.28/stroom_core/volumes/nginx/conf/nginx.conf.template`

```diff
--- 
+++ 
@@ -59,10 +59,6 @@
         # Include location configuration specific to proxy
         include locations.proxy.conf;
 
-        # Include location configuration specific to dev.
-        # Should not be included in production deployments.
-        # Supports hot-loading for stroom-ui
-        include locations.dev.conf;
     }
 }
 
```

### Diff for server.conf.template

From: `./build/stroom-stacks-v6.0.26/stroom_core/volumes/nginx/conf/server.conf.template`

To:   `./build/stroom-stacks-v6.0.28/stroom_core/volumes/nginx/conf/server.conf.template`

```diff
--- 
+++ 
@@ -9,7 +9,7 @@
 # The server's private key
 ssl_certificate_key         /stroom-nginx/certs/<<<NGINX_SSL_CERTIFICATE_KEY>>>;
 # The public CA cert for verifying client certs
-ssl_client_certificate      /stroom-nginx/certs/<<<NGINX_SSL_CLIENT_CERTIFICATE>>>;
+ssl_client_certificate      /stroom-nginx/certs/<<<NGINX_SSL_CA_CERTIFICATE>>>;
 
 # These two need to be on otherwise we won't be able to extract the DN or the cert
 # In order to capture the DN in the headers/logs, ssl_client_verify needs to be set
```

### Diff for config.yml

From: `./build/stroom-stacks-v6.0.26/stroom_core/volumes/stroom-auth-service/config/config.yml`

To:   `./build/stroom-stacks-v6.0.28/stroom_core/volumes/stroom-auth-service/config/config.yml`

```diff
--- 
+++ 
@@ -139,3 +139,8 @@
   # That regex won't work when pasted directly into this YAML.
   minimumPasswordLength: ${MINIMUM_PASSWORD_LENGTH:-8}
   passwordComplexityRegex: ${PASSWORD_COMPLEXITY_REGEX:-.*}
+
+stroom:
+  clientId: ${STROOM_CLIENT_ID:-PZnJr8kHRKqnlJRQThSI}
+  clientSecret: ${STROOM_CLIENT_SECRET:-OtzHiAWLj8QWcwO2IxXmqxpzE2pyg0pMKCghR2aU}
+  clientHost: ${STROOM_CLIENT_URI:-<IP_ADDRESS>}```

### Diff for nginx.conf.template

From: `./build/stroom-stacks-v6.0.26/stroom_core/volumes/stroom-auth-ui/conf/nginx.conf.template`

To:   `./build/stroom-stacks-v6.0.28/stroom_core/volumes/stroom-auth-ui/conf/nginx.conf.template`

```diff
--- 
+++ 
@@ -20,7 +20,7 @@
 
         ssl_certificate         /etc/nginx/certs/${NGINX_SSL_CERTIFICATE};
         ssl_certificate_key     /etc/nginx/certs/${NGINX_SSL_CERTIFICATE_KEY};
-        ssl_client_certificate  /etc/nginx/certs/${NGINX_SSL_CLIENT_CERTIFICATE};
+        ssl_client_certificate  /etc/nginx/certs/${NGINX_SSL_CA_CERTIFICATE};
 
         # Prevent clickjacking attacks. More details here:
         # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
@@ -32,8 +32,10 @@
 
         # Enable Content Security Policy (CSP) so the browser only downloads content 
         # from our domain. 
-        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'"; 
+        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; object-src 'none'; base-uri 'none'; frame-ancestors 'self'";
 
+        # Prevent mime based attacks
+        add_header X-Content-Type-Options "nosniff";
 
         location / {
             try_files $uri /index.html;
```

### Diff for crontab.env

From: `./build/stroom-stacks-v6.0.26/stroom_core/volumes/stroom-log-sender/conf/crontab.env`

To:   `./build/stroom-stacks-v6.0.28/stroom_core/volumes/stroom-log-sender/conf/crontab.env`

```diff
--- 
+++ 
@@ -5,7 +5,6 @@
 # the container by docker.
 # TODO We need to consider using supercronic instead of cron as it is better suited to
 # running in a container.
-
 
 # shellcheck disable=SC2034
 {
@@ -18,14 +17,6 @@
     LOG_SENDER_SCRIPT="/stroom-log-sender/send_to_stroom.sh"
     # The root path of all the logs
     ROOT_LOGS_DIR="/stroom-log-sender/log-volumes"
-    # The base path for all stroom logs
-    STROOM_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom"
-    # The base path for all stroom proxy logs
-    STROOM_PROXY_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom-proxy"
-    # The base path for all stroom auth service logs
-    STROOM_AUTH_SVC_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom-auth-service"
-    # The base path for all stroom nginx logs
-    STROOM_NGINX_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom-nginx"
     # The default regex used to identify log files ready to send
     DEFAULT_FILE_REGEX=".*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}\.log(\.gz)?$"
     # Regex for logrotate dated files, e.g. access.log-20181130-1543576470.gz
@@ -40,4 +31,26 @@
     CERT_FILE="/stroom-log-sender/certs/client.pem.crt"
     # The PEM format CA certificate
     CA_CERT_FILE="/stroom-log-sender/certs/ca.pem.crt"
+
+
+    # The following env vars are used to define the log directories that
+    # stroom-log-sender will look in to find logs. These vars are used by the
+    # crontab entries in crontab.txt. Each directory should be the mount point
+    # for a docker managed volume that is shared between the container producing
+    # the logs and stroom-log-sender. Remove any entires for services that are
+    # not in the stack.
+
+    # The base path for all stroom logs
+    STROOM_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom"
+
+    # The base path for all stroom proxy logs
+    STROOM_PROXY_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom-proxy"
+
+
+    # The base path for all stroom auth service logs
+    STROOM_AUTH_SVC_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom-auth-service"
+
+    # The base path for all stroom nginx logs
+    STROOM_NGINX_BASE_LOGS_DIR="${ROOT_LOGS_DIR}/stroom-nginx"
+
 }
```

### Diff for crontab.txt

From: `./build/stroom-stacks-v6.0.26/stroom_core/volumes/stroom-log-sender/conf/crontab.txt`

To:   `./build/stroom-stacks-v6.0.28/stroom_core/volumes/stroom-log-sender/conf/crontab.txt`

```diff
--- 
+++ 
@@ -1,14 +1,14 @@
 # Here for debugging
 #* * * * * source /stroom-log-sender/config/crontab.env; echo "${DATAFEED_URL}Cron running" >> /stroom-log-sender/cron.out
 
-# All of the entries here first source the crontab.env file. The cron implementation in alpine
+# All of the entries here first source the crontab.env file. The cron implementation in alpine linux
 # doesn't seem to support env vars in the crontab itself.  The env file allows reuse of the values, 
 # and makes it easier to change values by chamnging them in one place.
 
 # NOTE: Any changes to this crontab.txt file or the crontab.env file will require the container
 # to be restarted, as on boot, the container will load this file into cron
 
-## stroom logs
+# stroom logs
 * * * * * source /stroom-log-sender/config/crontab.env; ${LOG_SENDER_SCRIPT} ${STROOM_BASE_LOGS_DIR}/access STROOM-ACCESS-EVENTS STROOM ${DEFAULT_ENVIRONMENT} ${DATAFEED_URL} --file-regex "${DEFAULT_FILE_REGEX}" -m ${MAX_DELAY_SECS} --key ${PRIVATE_KEY_FILE} --cert ${CERT_FILE} --cacert ${CA_CERT_FILE} --delete-after-sending --no-secure --compress --headers ${STROOM_BASE_LOGS_DIR}/extra_headers.txt > /dev/stdout
 * * * * * source /stroom-log-sender/config/crontab.env; ${LOG_SENDER_SCRIPT} ${STROOM_BASE_LOGS_DIR}/app    STROOM-APP-EVENTS    STROOM ${DEFAULT_ENVIRONMENT} ${DATAFEED_URL} --file-regex "${DEFAULT_FILE_REGEX}" -m ${MAX_DELAY_SECS} --key ${PRIVATE_KEY_FILE} --cert ${CERT_FILE} --cacert ${CA_CERT_FILE} --delete-after-sending --no-secure --compress --headers ${STROOM_BASE_LOGS_DIR}/extra_headers.txt > /dev/stdout
 * * * * * source /stroom-log-sender/config/crontab.env; ${LOG_SENDER_SCRIPT} ${STROOM_BASE_LOGS_DIR}/user   STROOM-USER-EVENTS   STROOM ${DEFAULT_ENVIRONMENT} ${DATAFEED_URL} --file-regex "${DEFAULT_FILE_REGEX}" -m ${MAX_DELAY_SECS} --key ${PRIVATE_KEY_FILE} --cert ${CERT_FILE} --cacert ${CA_CERT_FILE} --delete-after-sending --no-secure --compress --headers ${STROOM_BASE_LOGS_DIR}/extra_headers.txt > /dev/stdout
@@ -24,6 +24,8 @@
 * * * * * source /stroom-log-sender/config/crontab.env; ${LOG_SENDER_SCRIPT} ${STROOM_PROXY_BASE_LOGS_DIR}/send    STROOM_PROXY-SEND-EVENTS    STROOM-PROXY ${DEFAULT_ENVIRONMENT} ${DATAFEED_URL} --file-regex "${DEFAULT_FILE_REGEX}" -m ${MAX_DELAY_SECS} --key ${PRIVATE_KEY_FILE} --cert ${CERT_FILE} --cacert ${CA_CERT_FILE} --delete-after-sending --no-secure --compress --headers ${STROOM_PROXY_BASE_LOGS_DIR}/extra_headers.txt > /dev/stdout
 * * * * * source /stroom-log-sender/config/crontab.env; ${LOG_SENDER_SCRIPT} ${STROOM_PROXY_BASE_LOGS_DIR}/receive STROOM_PROXY-RECEIVE-EVENTS STROOM-PROXY ${DEFAULT_ENVIRONMENT} ${DATAFEED_URL} --file-regex "${DEFAULT_FILE_REGEX}" -m ${MAX_DELAY_SECS} --key ${PRIVATE_KEY_FILE} --cert ${CERT_FILE} --cacert ${CA_CERT_FILE} --delete-after-sending --no-secure --compress --headers ${STROOM_PROXY_BASE_LOGS_DIR}/extra_headers.txt > /dev/stdout
 
+
 # stroom-nginx logs
 * * * * * source /stroom-log-sender/config/crontab.env; ${LOG_SENDER_SCRIPT} ${STROOM_NGINX_BASE_LOGS_DIR}/access STROOM_NGINX-ACCESS-EVENTS STROOM-NGINX ${DEFAULT_ENVIRONMENT} ${DATAFEED_URL} --file-regex "${LOGROTATE_DATED_REGEX}" -m ${MAX_DELAY_SECS} --key ${PRIVATE_KEY_FILE} --cert ${CERT_FILE} --cacert ${CA_CERT_FILE} --delete-after-sending --no-secure --compress --headers ${STROOM_NGINX_BASE_LOGS_DIR}/extra_headers.txt > /dev/stdout
 * * * * * source /stroom-log-sender/config/crontab.env; ${LOG_SENDER_SCRIPT} ${STROOM_NGINX_BASE_LOGS_DIR}/app    STROOM_NGINX-APP-EVENTS    STROOM-NGINX ${DEFAULT_ENVIRONMENT} ${DATAFEED_URL} --file-regex "${LOGROTATE_DATED_REGEX}" -m ${MAX_DELAY_SECS} --key ${PRIVATE_KEY_FILE} --cert ${CERT_FILE} --cacert ${CA_CERT_FILE} --delete-after-sending --no-secure --compress --headers ${STROOM_NGINX_BASE_LOGS_DIR}/extra_headers.txt > /dev/stdout
+
```

## Changes to the Docker image versions

```diff
--- 
+++ 
@@ -2 +2 @@
-stroom|gchq/stroom:v6.0.26
+stroom|gchq/stroom:v6.0.28
@@ -4,2 +4,2 @@
-stroom-auth-service|gchq/stroom-auth-service:v6.0.25
-stroom-auth-ui|gchq/stroom-auth-ui:v6.0.25
+stroom-auth-service|gchq/stroom-auth-service:v6.0.27-1
+stroom-auth-ui|gchq/stroom-auth-ui:v6.0.27-1
@@ -7 +7 @@
-stroom-proxy-local|gchq/stroom-proxy:v6.0.26
+stroom-proxy-local|gchq/stroom-proxy:v6.0.28
```

<!-- vim: set filetype=markdown -->