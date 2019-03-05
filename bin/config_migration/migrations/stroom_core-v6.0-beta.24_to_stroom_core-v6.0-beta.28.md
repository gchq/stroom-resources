# Differences between stroom_core-v6.0-beta.24 and stroom_core-v6.0-beta.28

## Added

AUTH_SERVICE_HOST=$HOST_IP
STROOM_AUTH_SERVICE_DEBUG_PORT=10769
STROOM_CONTENT_PACK_IMPORT_ENABLED=true
STROOM_STREAM_TASK_SERVICE_HOST=$HOST_IP
STROOM_UI_DOCKER_REPO=gchq/stroom-ui
STROOM_UI_HOST=$HOST_IP
STROOM_UI_HTTPS_PORT=9444
STROOM_UI_HTTP_PORT=5001
STROOM_UI_PATH=/stroom/ui?prompt=login
STROOM_UI_STD_OUT_LOGS_MAX_FILES=2
STROOM_UI_STD_OUT_LOGS_MAX_SIZE=10m
STROOM_UI_TAG=v1.0-LATEST
STROOM_UI_VOLUME_CERTS=../../volumes/stroom-ui/certs
STROOM_UI_VOLUME_CONF=../../volumes/stroom-ui/conf

## Removed

CTOP_DOCKER_REPO=quay.io/vektorlab/ctop
CTOP_TAG=latest

## Changed default values

STROOM_AUTH_EMAIL_SMTP_PASSWORD has changed from "TODO" to ""
STROOM_UI_URL has changed from "http://localhost:5001/" to "$HOST_IP:5001"
STROOM_PROXY_TAG has changed from "v6.0-beta.24" to "v6.0-beta.28"
STROOM_TAG has changed from "v6.0-beta.24" to "v6.0-beta.28"
STROOM_AUTH_SERVICE_JAVA_OPTS has changed from " -Xms50m -Xmx1024m " to " -Xms50m -Xmx1024m -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=10769,suspend=n"
STROOM_AUTH_UI_TAG has changed from "v1.0-beta.23" to "v1.0-beta.29"
STROOM_AUTH_SERVICE_TAG has changed from "v1.0-beta.23" to "v1.0-beta.29"
STROOM_NGINX_TAG has changed from "v1.0-alpha.13" to "v1.0-alpha.15"
STROOM_AUTH_EMAIL_SMTP_USERNAME has changed from "TODO" to ""

## Variables that occur more than once within the stroom_core-v6.0-beta.24 env file

STROOM_ANNOTATIONS_UI_URL is defined twice, as "http://$HOST_IP:5001" and as "http://$HOST_IP/annotations"
STROOM_AUTH_UI_ACTIVE_SCHEME is defined twice, as "http" and as "https"
STROOM_AUTH_UI_URL is defined twice, as "$HOST_IP:5000" and as "$HOST_IP:9443"
STROOM_JAVA_OPTS is defined twice, as " -Xms50m -Xmx1024m " and as " -Xms50m -Xmx1024m -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=10765,suspend=n "
STROOM_PROXY_LOCAL_SYNC_API_KEY is defined twice, as "" and as "http://stroom:8080/api/dictionary/v1"
STROOM_PROXY_LOCAL_UPSTREAM_DICTIONARY_URL is defined twice, as "https://nginx/dictionaryService/v1" and as "http://stroom:8080/api/dictionary/v1"
STROOM_PROXY_LOCAL_UPSTREAM_RULE_URL is defined twice, as "https://nginx/rulesetService/v1" and as "http://stroom:8080/api/ruleset/v1"
STROOM_PROXY_REMOTE_FORWARD_URL is defined twice, as "https://nginx/stroom/datafeed" and as "http://stroom-proxy-local:8090/stroom/datafeed"
STROOM_PROXY_REMOTE_SYNC_API_KEY is defined twice, as "" and as "http://stroom:8080/api/dictionary/v1"
STROOM_PROXY_REMOTE_UPSTREAM_DICTIONARY_URL is defined twice, as "https://nginx/dictionaryService/v1" and as "http://stroom-proxy-local:8090/api/dictionary/v1"
STROOM_PROXY_REMOTE_UPSTREAM_RULE_URL is defined twice, as "https://nginx/rulesetService/v1" and as "http://stroom-proxy-local:8090/api/ruleset/v1"
STROOM_QUERY_ELASTIC_UI_URL is defined twice, as "http://$HOST_IP:5002" and as "http://$HOST_IP/query-elastic"

## Variables that occur more than once within the stroom_core-v6.0-beta.28 env file

STROOM_ANNOTATIONS_UI_URL is defined twice, as "http://$HOST_IP:5001" and as "http://$HOST_IP/annotations"
STROOM_AUTH_UI_ACTIVE_SCHEME is defined twice, as "http" and as "https"
STROOM_AUTH_UI_URL is defined twice, as "$HOST_IP:5000" and as "$HOST_IP:9443"
STROOM_JAVA_OPTS is defined twice, as " -Xms50m -Xmx1024m " and as " -Xms50m -Xmx1024m -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=10765,suspend=n "
STROOM_PROXY_LOCAL_SYNC_API_KEY is defined twice, as "" and as "http://stroom:8080/api/dictionary/v1"
STROOM_PROXY_LOCAL_UPSTREAM_DICTIONARY_URL is defined twice, as "https://nginx/dictionaryService/v1" and as "http://stroom:8080/api/dictionary/v1"
STROOM_PROXY_LOCAL_UPSTREAM_RULE_URL is defined twice, as "https://nginx/rulesetService/v1" and as "http://stroom:8080/api/ruleset/v1"
STROOM_PROXY_REMOTE_FORWARD_URL is defined twice, as "https://nginx/stroom/datafeed" and as "http://stroom-proxy-local:8090/stroom/datafeed"
STROOM_PROXY_REMOTE_SYNC_API_KEY is defined twice, as "" and as "http://stroom:8080/api/dictionary/v1"
STROOM_PROXY_REMOTE_UPSTREAM_DICTIONARY_URL is defined twice, as "https://nginx/dictionaryService/v1" and as "http://stroom-proxy-local:8090/api/dictionary/v1"
STROOM_PROXY_REMOTE_UPSTREAM_RULE_URL is defined twice, as "https://nginx/rulesetService/v1" and as "http://stroom-proxy-local:8090/api/ruleset/v1"
STROOM_QUERY_ELASTIC_UI_URL is defined twice, as "http://$HOST_IP:5002" and as "http://$HOST_IP/query-elastic"
STROOM_UI_URL is defined twice, as "$HOST_IP:5001" and as "http://localhost:5001/"
STROOM_UI_URL is defined twice, as "$HOST_IP:5001" and as "https://$HOST_IP:STROOM_UI_HTTP_PORT"
