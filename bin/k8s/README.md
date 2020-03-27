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

### Progress

#### 2020-03-27

Getting entirely into k8s is a big job and it's not finished yet. As of today `stroom` is connecting to `stroom-all-dbs` and nginx is mostly being created but the mount volumes all need to use config maps. There is already an example of how to do this for the init scripts in `stroom-all-dbs`. After this nginx will probably need the HOST_IPs updating with the names of services, and it'll need an ingress resource. If NGINX uses k8s service names then it obviously won't work if stroom is running outside a container, so it'll be no good for dev. This needs figuring out.
