# Stroom Environment Variable Documentation

The following environment variable are used to configure the stroom stacks.

This file is also used as a source for adding in-line documentation to the
`.env` file in the stack configuration (see create_stack_env.sh). For the
documentation to be included, the environment variable name must appear as a
second level heading, i.e. `## ENV_VAR_NAME`. All non-blank lines after that
will be included as documentation for that environment variable.

Variables shoule be listed in A-Z order. Text should have hard breaks before 80
chars.

## NGINX_ADVERTISED_HOST

The public hostname or IP address of the nginx host.  This address will be used
by all services that need to route requests via nginx.

## STROOM_NGINX_DOCKER_REPO

The docker repository for the stroom-nginx docker image, e.g.
`gchq/stroom-nginx`. This can be changed to use a local repository.

## STROOM_DB_HOST

The hostname or IP address of the database host for the stroom database.
