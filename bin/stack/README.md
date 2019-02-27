# Pre-canned docker stacks

This directory contains a set of shell scripts for creating a pre-canned stroom stack to be run in docker.

## Running a pre-canned stack

Open the tar file using something like this:

```bash
mkdir ./myStack
cd myStack
tar -xvf ~/Downloads/stroom_core*.tar.gz
```

To start the stack do:

```bash
./start.sh
```

For more details on managing the stack see the README file in the stack tar file.


## Creating a stack

There are a number of forms of the stack to cater for different deployments

* _stroom_core_ - This contains the bare minimum to run stroom. It is intended for running stroom in small scale non-clustered deployments.
* _stroom_core_test_ - This stack is similar to _stroom_core_ but includes pre-loaded content. It is intended for testing or evaluation purposes.
* _stroom_full_ - This stack contains stroom and all essenntial and non-essential services.
* _stroom_dbs_ - This stack contains just a MySQL database.

The required stack can be created locally using the appropriate build script.
The build scipt for a stack takes the form `./build_<STACK_NAME>.sh` 


### Common stack configuration

All stacks are governed by the docker container versions specified in `./container_versions.env`.


### Stack definitions

Each stack has a set of definition files that are located in a sub-directory of `./stack_definitions`.
The sub-directory has the same name as the stack, e.g. `./stack_definitions/stroom_core`.

Each sub-directory can contain the following files:


#### `env_vars_whitelist.txt`

This file specifies a list of environment variable names that should be extracted from the YAML configuration and placed in the `.env` file of the stack.

The format of a line is just the name of the variable, e.g.

``` bash
A_WHITELISTED_ENV_VAR
```

#### `volumes_whitelist.txt`

This file contains a whitelist of the named docker volumes present at the bottom of `everything.yml` that will be included in the build stack.

An example file looks like this:

```
stroom-all-dbs_data
stroom-all-dbs_logs
```


#### `overrides.env`

This file contains overrides to substitution variables found in the docker compose `.yml` files located in `../compose/containers/`.

For example, if `stroom.yml` contains a line like

``` yaml
  image: "${STROOM_REPO:-gchq/stroom}:${STROOM_TAG:-v6.0-LATEST}"
```

and the `overrides.env` file contains

``` bash
STROOM_TAG="v6.1.2"
```

Then the resulting stack `.yml` file becomes:

``` yaml
  image: "${STROOM_REPO:-gchq/stroom}:v6.1.2"
```


## Releasing a stack to GitHub

To create a new release of the stack do the following:

1. Edit the file `./container_versions.env` and set the required versions for each image.
1. Commit the version changes and push.
1. Create an annotated git tag along the lines of:
    1. `git tag -a stroom_core-v6.0-beta.3` # it is crtical the tag begins `stroom_core` or `stroom_full`.
    1. `git push origin stroom_core-v6.0-beta.3`
1. Travis will now build the stack and release it to GitHub at [github.com/gchq/stroom-resources/releases](https://github.com/gchq/stroom-resources/releases).

