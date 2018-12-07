#!/bin/bash

host=${1:-localhost}
port=${2:-443}

if [ ! -f /tmp/SSLPoke.class ]; then
    pushd /tmp > /dev/null
    # see https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-779355358.html
    wget https://confluence.atlassian.com/kb/files/779355358/779355357/1/1441897666313/SSLPoke.class
    popd > /dev/null
fi

echo "Connecting to ${host} ${port}"

#-Djavax.net.debug=ssl \
${JAVA_HOME}/bin/java \
    -cp "/tmp" \
    -Djavax.net.ssl.keyStore=${HOME}/git_work/stroom-resources/dev-resources/certs/server/server.jks \
    -Djavax.net.ssl.keyStoreType=JKS \
    -Djavax.net.ssl.keyStorePassword=password \
    -Djavax.net.ssl.trustStore=${HOME}/git_work/stroom-resources/dev-resources/certs/server/ca.jks \
    -Djavax.net.ssl.trustStoreType=JKS \
    -Djavax.net.ssl.trustStorePassword=password \
    SSLPoke \
    "${host}" \
    "${port}"
