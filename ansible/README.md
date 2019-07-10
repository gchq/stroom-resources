# stroom-ansible

This repo contains the ansible scripts necessary for setting up a multi-node Stroom v6.0.

## Assumptions and caveats

- You have a number of machines available. a minimum of 3.
- These machines don't have any firewalls running.
- You're using the following host groups/stacks: `stroom_and_proxy`, `stroom_services`, `stroom_dbs`.

These will change as the ansible scripts evolve.

This has been tested on AWS. The AMI used is `ami-0ff760d16d9497663`, a Centos 7.0 image.

## Getting the Ansible scripts

`git clone https://github.com/gchq/stroom-resources`

The ansible scripts are in `stroom-resources/ansible`.

## Setting up your configuration

The repository contains only the ansible scripts. You need to store your Stroom configuration somewhere else, i.e. not a public GitHub repository. You need the following:

 - a `hosts` file -- you need to add this location to `ansible.cfg`, the `inventory` key. An example is in `examples/hosts`.
 - your stroom configuration files -- these are the files that configure the stroom services themselves, and they're copied onto the hosts when you run the `update_config` playbook. An example is in `examples/conf`.

## Updating the inventory

The inventory file `./hosts` needs to contain all the host names of the vms. It's split into host groups so enter your VMs under the appropriate section if you've sized them according to their tasks.

You need a service name; an FQDN that the user will visit. This name is important and needs to be used in a few places within the configuration. For this name you could take the first host name in the `stroom_services` host group.

You also need the host name of the database machine.

The following all need the database host name
 - `./conf/stroom_services/stroom_services.env` - update:
   - `STROOM_AUTH_DB_HOST`
 - `./conf/stroom_and_proxy/stroom_and_proxy.en`v - update:
   - `STROOM_DB_HOST`
   - `STROOM_STAT_SDB_HOST`

The following all need the service name:
 - `./conf/nginx/server.conf.template`
 - `./conf/stroom_services/stroom_services.env`, the following variables:
   - `HOST_IP`
 - `./conf/stroom_and_proxy/stroom_and_proxy.env`, the following variables:
   - `HOST_IP`

NGINX reverse-proxies everything, so we need to tell nginx where the hosts live. These are in the upstream files. You'll want to update these to match how you updated `hosts`. Stroom and Proxy will have more or less the same upstreams.
 - `./conf/nginx/upstreams.auth.conf.template`
 - `./conf/nginx/upstreams.stroom.conf.template`
 - `./conf/nginx/upstreams.proxy.conf.template`
   
You'll also need to update the two redirects in `./conf/nginx/locations.stroom.conf.template`.

## Setting up the hosts

```
ansible-playbook -i hosts setup_hosts.yml
```

## Installing the stacks

```
ansible-playbook -i hosts install_stack.yml
```

## Copying the config to the nodes

You have the stacks but you need to make sure the config you changed above is copied to the nodes. 
```
ansible-playbook -i hosts update_config.yml
```

## Controlling the stacks

A Stroom stack has several scripts to control it. 
 - To start and stop: start/stop/restart
 - To get information about the stack: health/info/show_config/logs/status
 - To clean up: remove

NB/TODO: logs doesn't work very well because it tails and doesn't complete.

If you want to execute these on all stacks do the following:
```
ansible-playbook -i hosts run_script_on_all.yml
```

You will then be prompted for the script you want to run. There are currently no checks to make sure you've entered a valid script, so get it right. 

You can also run these on a single host group by running a similarly named script:
```
ansible-playbook -i hosts run_script.yml
```

This will prompt you for the host group.

You can bypass the prompt for either of these as follows:
```
ansible-playbook -i hosts run_script_on_all.yml --extra-vars "op=restart"
ansible-playbook -i hosts run_script_on_all.yml --extra-vars "op=restart stack_type=stroom_services"
```

## Removing a stack
You can do the following to remove all the containers:
```
ansible-playbook -i hosts run_script_on_all.yml --extra-vars "op=remove"
```

You can then delete all the files that were moved there:
```
ansible-playbook -i hosts delete.yml
```
