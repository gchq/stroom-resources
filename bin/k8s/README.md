# k8s config for Stroom

Work-in-progress config for running Stroom in k8s.

## Prerequisites

* minikube
* kubectl

## Running

Use the `run` script. Invoke `./run` to see what commands are available, then invoke a function by invoking, for example, `./run apply`.

Note: 'apply' takes the config and makes it live. If the resources don't exist it'll create them (i.e. deploy Stroom), and if they do it'll update them with any changes.

## Notes

### Configuring MySQL

Each config file is added to a ConfigMap. We can then use this ConfigMap item as the target for a mounted volume.
