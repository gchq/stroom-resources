# Differences between stroom_core-v6.0-beta.21 and stroom_core-v6.0-beta.24

## Added

STROOM_AUTH_DURATION_BETWEEN_CHECKS=PT2M
STROOM_AUTH_MANDATORY_PASSWORD_CHANGE_DURATION=P30D
STROOM_AUTH_NEVER_USED_ACCOUNT_DEACTIVATION_THRESHOLD=P30D
STROOM_AUTH_UNUSED_ACCOUNT_DEACTIVATION_THRESHOLD=P90D
STROOM_SECURITY_API_TOKEN_DURATION_TO_WARN_BEFORE_EXPIRY=30d

## Removed

STROOM_AUTH_DISABLE_INACTIVE_ACCOUNT_AFTER_X_MINS=12900
STROOM_AUTH_DISABLE_INACTIVE_NEW_ACCOUNT_AFTER_X_MINS=43200
STROOM_AUTH_REQUIRE_PASSWORD_CHANGE_AFTER_X_MINS=43200
STROOM_AUTH_SECONDS_BETWEEN_PASSWORD_INTEGRITY_CHECKS=3600

## Changed default values

STROOM_PROXY_TAG has changed from "v6.0-beta.21" to "v6.0-beta.24"
STROOM_AUTH_UI_TAG has changed from "v1.0-beta.18" to "v1.0-beta.23"
STROOM_AUTH_SERVICE_TAG has changed from "v1.0-beta.18" to "v1.0-beta.23"
STROOM_TAG has changed from "v6.0-beta.21" to "v6.0-beta.24"
STROOM_SECURITY_API_TOKEN has changed from "eyJhbGciOiJSUzI1NiJ9.eyJleHAiOjE1NDQ4NjMwNDMsInN1YiI6InN0cm9vbVNlcnZpY2VVc2VyIiwiaXNzIjoic3Ryb29tIn0.gHJkpxeW5CjU_hBzuLhQd8Ot8XkLvhu45_-Ql4gOX96iNbl0AnKEwKu2QmMY3uVerGjYBHDczgKJlLVF_RQtFiwFLorT2P_Mv-9ShcCL0Ml-Tq-1i-_UnHMYHP5Nv-rP3ajUz-vTHwIYqi_WU-IEpIF56MCYBqeDkgQfe-I03VyfsLkWt-3f8L3AKESZirmqjPUB_SPi4vWGpyN28FuJe1KyqdCPo5QVKnrM_dpguE_aIj1Dy1sovmgO5WxFm3-hE7asW3WrnokSopNXQ1bJ3W77v4k1CnMpYDw5schQAKqUffPVGxNE6UxNunZTlRQJQqYihKkhpeiTiZMo9XCHGg" to "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzcyI6InN0cm9vbSIsInNpZCI6bnVsbH0.k0Ssb43GCdTunAMeM26fIulYKNUuPUaJJk6GxDmzCPb7kVPwEtdfBSrtwazfEFM97dnmvURkLqs-DAZTXhhf-0VqQx4hkwcCHf83eVptWTy-lufIhQo6FCM223c9ONIhl6CPqknWh9Bo3vFNrNJoKz5Zw2T_iCcQhi2WGjd_tjTG7VbibTIpH3lPQDw1IBD2nMsEqACJSk3IaFe0GYcrAEMwsjj3sjAwByMbj5DJvo_DJbAuzUwS5IVpASEENen5Xd3wALLirrraUfED1OY0G56Ttcwl3uQ2s-grZXBM4JCiIurlWR5iNtNwoPUsZsyMju4FMSXt3Ur1NIpD7XKJlg"

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
