# Stroom Environment Variable Documentation

The following environment variables are used to configure the stroom stacks.

This file is also used as a source for adding in-line documentation to the
`.env` file in the stack configuration (see create_stack_env.sh). For the
documentation to be included, the environment variable name must appear as a
second level heading, i.e. `## ENV_VAR_NAME`. All non-blank lines after that
will be included as documentation for that environment variable.

Variables should be listed in A-Z order. Text should have hard breaks before 80
chars.


## MYSQL_DOCKER_REPO

The docker repository for the mysql docker image, e.g.  `mysql`. This can be
changed to use a local repository.

## NGINX_ADVERTISED_HOST

The public hostname or IP address of the nginx host.  This address will be used
by all services that need to route requests via nginx.

## NGINX_SSL_CERTIFICATE

The PEM format certificate file that nginx will use as the server certificate
for authenticating requests.  This certificate should have the host/DNS names
of the nginx host(s) in its SAN list. The value is the filename only, without
any path information, e.g. `server.crt`.

## NGINX_SSL_CERTIFICATE_KEY

The PEM format private key file that nginx will use for authenticating
requests. The value is the filename only, without any path information, e.g.
`server.key`.

## NGINX_SSL_CA_CERTIFICATE

The certificate authority certificate that nginx will use for authenticating
requests. This should be the same certificate authority that signed the server
certificate.

## STROOM_AUTH_DB_HOST

The hostname or IP address of the database host for the _auth_ database.

## STROOM_AUTH_DB_PASSWORD

The password for the _auth_ database.

## STROOM_AUTH_EMAIL_FROM_ADDRESS

The from address that will be used when sending password reset emails from
stroom-auth.

## STROOM_AUTH_EMAIL_SMTP_HOST

The hostname or IP address of the SMTP mail server that will be used when
sending password reset emails from stroom-auth.

## STROOM_AUTH_EMAIL_SMTP_PORT

The port of the SMTP mail server that will be used when sending password reset
emails from stroom-auth.

## STROOM_AUTH_SERVICE_DOCKER_REPO

The docker repository for the stroom-auth-service docker image, e.g.
`gchq/stroom-auth-service`. This can be changed to use a local repository.

## STROOM_AUTH_SERVICE_HOST

The host/DNS name used to access stroom-auth-service. Typically this will be
the same as NGINX_ADVERTISED_HOST when nginx is used as the gateway for all
requests.

## STROOM_AUTH_SERVICE_JAVA_OPTS

Any additional java command line options, e.g. `-Xms50m -Xmx1024m`, that will
be used when running stroom-auth-service.

## STROOM_AUTH_UI_DOCKER_REPO

The docker repository for the stroom-auth-ui docker image, e.g.
`gchq/stroom-auth-ui`. This can be changed to use a local repository.

## STROOM_AUTH_UI_HOST

The host/DNS name used to access the stroom-auth user interface. Typically this
will be the same as NGINX_ADVERTISED_HOST when nginx is used as the gateway for
all requests.

## STROOM_DB_HOST

The hostname or IP address of the database host for the _stroom_ database.

## STROOM_DB_PASSWORD

The password for the _stroom_ database.

## STROOM_DB_ROOT_PASSWORD

The root password for the mysql instance.

## STROOM_DOCKER_REPO

The docker repository for the stroom docker image, e.g.  `gchq/stroom`. This
can be changed to use a local repository.

## STROOM_HELP_URL

The URL that stroom will use for its help pages. The help content is served
from the gchq/stroom-docs github repository but can be served from a local web
server.

## STROOM_HOST

The host/DNS name used to access stroom. Typically this will be the same as
NGINX_ADVERTISED_HOST when nginx is used as the gateway for all requests.

## STROOM_JAVA_OPTS

Any additional java command line options, e.g. `-Xms50m -Xmx1024m`, that will
be used when running stroom.

## STROOM_LOG_SENDER_CA_CERT_FILE

The certificate authority certificate that stroom-log-sender will use when
sending logs to a stroom or stroom-proxy instance.

## STROOM_LOG_SENDER_CERT_FILE

The client certificate that stroom-log-sender will use when sending logs to a
stroom or stroom-proxy instance.

## STROOM_LOG_SENDER_DATAFEED_URL

The URL to send logs to, i.e. stroom's `/stroom/datafeed` endpoint.

## STROOM_LOG_SENDER_DEFAULT_ENVIRONMENT

The environment name (e.g. DEV, REF, OPS, etc) that will be associated with the
sent logs, unless specified in `crontab.txt`

## STROOM_LOG_SENDER_DOCKER_REPO

The docker repository for the stroom docker image, e.g.
`gchq/stroom-log-sender`. This can be changed to use a local repository.

## STROOM_LOG_SENDER_PRIVATE_KEY_FILE

The client private key that stroom-log-sender will use when sending logs to a
stroom or stroom-proxy instance.

## STROOM_NGINX_DOCKER_REPO

The docker repository for the stroom-nginx docker image, e.g.
`gchq/stroom-nginx`. This can be changed to use a local repository.

## STROOM_NODE

The name of the stroom node. This is relevant when multiple stroom instances
are running.

## STROOM_PROXY_DOCKER_REPO

The docker repository for the stroom-proxy docker image, e.g.
`gchq/stroom-proxy`. This can be changed to use a local repository.

## STROOM_PROXY_HOST

The host/DNS name used to access stroom-proxy. Typically this will be the same
as NGINX_ADVERTISED_HOST when nginx is used as the gateway for all requests.

## STROOM_PROXY_LOCAL_FEED_STATUS_API_KEY

The API key (as generated on the Stroom => Tools => API Keys page) that
stroom-proxy (local) will use to authenticate with stroom in order to check the receipt
status of feeds.

## STROOM_PROXY_LOCAL_FEED_STATUS_URL

The URL that will be used by stroom-proxy (local) to check the receipt status
of feeds.

## STROOM_PROXY_LOCAL_FORWARDING_ENABLED

True if stroom-proxy should forward data on to a downstream stroom or
stroom-proxy instance. Typically this will be false for a local proxy, i.e. one
that is co-located with stroom.

## STROOM_PROXY_LOCAL_JERSEY_VERIFY_HOSTNAME

True if stroom-proxy should verify the hostname against the server certificate
when making API call, e.g. when checking the feed receipt status.

## STROOM_PROXY_LOCAL_STORING_ENABLED

True if stroom-proxy should store the received data in its local repository.
Typically this will be true for a local proxy as stroom will read from this
repository.

## STROOM_PROXY_REMOTE_CLIENT_KEYSTORE_PASSWORD

The password of the java keystore file that will be used when making API
class to a downstream stroom or stroom-proxy, e.g. checking feed receipt
status. Typically this will be in JKS format.

## STROOM_PROXY_REMOTE_CLIENT_KEYSTORE_PATH

The absolute path to the java keystore file that will be used when making API
class to a downstream stroom or stroom-proxy, e.g. checking feed receipt
status. Typically this will be in JKS format.

## STROOM_PROXY_REMOTE_CLIENT_TRUSTSTORE_PASSWORD

The password of the java truststore file that will be used when making API
class to a downstream stroom or stroom-proxy, e.g. checking feed receipt
status. Typically this will be in JKS format.

## STROOM_PROXY_REMOTE_CLIENT_TRUSTSTORE_PATH

The absolute path to the java truststore file that will be used when making API
class to a downstream stroom or stroom-proxy, e.g. checking feed receipt
status. Typically this will be in JKS format.

## STROOM_PROXY_REMOTE_FEED_STATUS_API_KEY

The API key (as generated on the Stroom => Tools => API Keys page) that
stroom-proxy (remote) will use to authenticate with stroom in order to check the receipt
status of feeds.

## STROOM_PROXY_REMOTE_FEED_STATUS_URL

The URL that will be used by stroom-proxy (remote) to check the receipt status
of feeds.

## STROOM_PROXY_REMOTE_FORWARDING_ENABLED

True if stroom-proxy should forward data on to a downstream stroom or
stroom-proxy instance. Typically this will be false for a local proxy, i.e. one
that is co-located with stroom.

## STROOM_PROXY_REMOTE_FORWARDING_KEYSTORE_PASSWORD

The password for the keystore file that will be used when forwarding
data to a downstream stroom or stroom-proxy.

## STROOM_PROXY_REMOTE_FORWARDING_KEYSTORE_PATH

The absolute path to the java keystore file that will be used when forwarding
data to a downstream stroom or stroom-proxy. Typically this will be in JKS
format.

## STROOM_PROXY_REMOTE_FORWARDING_TRUSTSTORE_PASSWORD

The password for the truststore file that will be used when forwarding
data to a downstream stroom or stroom-proxy.

## STROOM_PROXY_REMOTE_FORWARDING_TRUSTSTORE_PATH

The absolute path to the java truststore file that will be used when forwarding
data to a downstream stroom or stroom-proxy. Typically this will be in JKS
format.

## STROOM_PROXY_REMOTE_FORWARD_URL

The URL that data should be forwarded to, e.g. a downstream stroom or stroom-proxy.

## STROOM_PROXY_REMOTE_JERSEY_VERIFY_HOSTNAME

True if stroom-proxy should verify the hostname against the server certificate
when making API call, e.g. when checking the feed receipt status.

## STROOM_PROXY_REMOTE_STORING_ENABLED

True if stroom-proxy should store the received data in its local repository.
Typically this will be true for a local proxy as stroom will read from this
repository.

## STROOM_RACK

DEPRECATED The name/id of the rack in which this stroom instance sits.

## STROOM_SECURITY_API_TOKEN

This is the _stroomServiceUser_ API key as obtained from the Tools => API Keys
page. When deploying a new production stroom, a new API Key should be created
for _stroomServiceUser_ and its value copied here.

## STROOM_STATS_DB_HOST

The host/DNS name for the SQL Statistics _stats_ database.

## STROOM_STATS_DB_PASSWORD

The password for the SQL Statistics _stats_ database.

## STROOM_UI_HOST

The host/DNS name used to access the stroom user interface. Typically this will
be the same as NGINX_ADVERTISED_HOST when nginx is used as the gateway for all
requests.
