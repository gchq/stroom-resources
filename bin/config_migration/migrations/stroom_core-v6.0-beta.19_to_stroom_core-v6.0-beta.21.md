# Differences between stroom_core-v6.0-beta.19 and stroom_core-v6.0-beta.21

## Added


## Removed


## Changed default values

STROOM_PROXY_TAG has changed from "v6.0-beta.19" to "v6.0-beta.21"
STROOM_TAG has changed from "v6.0-beta.19" to "v6.0-beta.21"

## Variables that occur more than once within the stroom_core-v6.0-beta.19 env file

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

## Variables that occur more than once within the stroom_core-v6.0-beta.21 env file

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
