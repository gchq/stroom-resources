# Pre-canned docker stacks

This directory contains a set of shell scripts for creating a pre-canned stroom stack to be run in docker.

## Creating a stack

There are two forms of the stack, _core_ and _full_.

* _core_ - This contains the bare minimum to run stroom.
* _full_ - This stack contains stroom and all essenntial and non-essential services.

The required stack can be created locally using the following scripts

* `./buildCore.sh`
* `./buildFull.sh`

## Releasing a stack to GitHub

To create a new release of the stack do the following:

1. Edit the file `./container_versions.env` and set the required versions for each image.
1. Commit the version changes and push.
1. Create an annotated git tag along the lines of:
    1. `git tag -a stroom_core-v6.0-beta.3` # it is crtical the tag begins `stroom_core` or `stroom_full`.
    1. `git push origin stroom_core-v6.0-beta.3`
1. Travis will now build the stack and release it to GitHub at [github.com/gchq/stroom-resources/releases](https://github.com/gchq/stroom-resources/releases).

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
