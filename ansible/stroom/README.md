# stroom-ansible

This directory contains the ansible scripts necessary for setting up a multi-node Stroom v6.0.

## Assumptions and caveats

- You have a number of machines available. a minimum of 3.
- These machines don't have any firewalls running.
- You're using the following host groups/stacks: `stroom_and_proxy`, `stroom_services`, `stroom_dbs`.

These will change as the ansible scripts evolve.

This has been tested on AWS. The AMI used is `ami-0ff760d16d9497663`, a Centos 7.0 image.

## Getting the Ansible scripts

```sh
git clone https://github.com/gchq/stroom-resources
```

The ansible scripts are in `stroom-resources/ansible`.


## Choosing the location of your configuration

Nothing changes in this repository when configuring and running an environment. The files that are generated and used to configure the environment should be stored elsewhere and source controlled as you wish. You need to symlink to wherever these files reside, or will reside after they've been generated automatically. Do this, replacing the path where obvious:

``` sh
# Or 'ln -sf ...' if you're so inclined
ln --symbolic --force /path/to/your/config config 
```
 
## Updating the inventory

The location of the Ansible inventory file is defined in `ansible.cfg`. If you're using aws you can use the aws playbooks (also in this repository) to create your hosts and generate this file, otherwise you'll need to write it yourself, put it somewhere sensible, and update `ansible.cfg` with that location.

## The Stroom configuration
The `releases` folder contains stack releases. The symlink `latest` should always point to the most recent one. That's the location used by the playbooks to find the config it needs to send to the hosts.


 - your stroom configuration files -- these are the files that configure the stroom services themselves, and they're copied onto the hosts when you run the `update_config` playbook. An example is in `examples/conf`.

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

```sh
ansible-playbook -i hosts setup_hosts.yml
```

## Installing the stacks

```sh
ansible-playbook -i hosts install_stack.yml
```

## Copying the config to the nodes

You have the stacks but you need to make sure the config you changed above is copied to the nodes. 
```sh
ansible-playbook -i hosts update_config.yml
```

## Controlling the stacks

A Stroom stack has several scripts to control it. 
 - To start and stop: start/stop/restart
 - To get information about the stack: health/info/show_config/logs/status
 - To clean up: remove

### Controlling the stack using tmux
Although tmux involves opening several ssh sessions to the boxes and is therefore terribly old-school, it is also much easier to work with than using ansible to control and monitor a stack. I.e. you can use ansible to set up your environments, install and update stroom and its config, but you might have more joy using tmux for control and monitoring.

You can create a tmuxinator layout from your ansible inventory by running:

``` 
./scripts/create_tmuxinator_layout.sh stroom_test
```
In the above `stroom_test` is the name of the layout. Then you can use that name to start a tmux session, automatically connecting to your hosts:

``` sh
tmuxinator stroom_test
```

### Controlling the stack using ansible
NB/TODO: logs doesn't work very well because it tails and doesn't complete.

If you want to execute these on all stacks do the following:
```sh
ansible-playbook -i hosts run_script_on_all.yml
```

You will then be prompted for the script you want to run. There are currently no checks to make sure you've entered a valid script, so get it right. 

You can also run these on a single host group by running a similarly named script:
```sh
ansible-playbook -i hosts run_script.yml
```

This will prompt you for the host group.

You can bypass the prompt for either of these as follows:
```sh
ansible-playbook -i hosts run_script_on_all.yml --extra-vars "op=restart"
ansible-playbook -i hosts run_script_on_all.yml --extra-vars "op=restart stack_type=stroom_services"
```

## Removing a stack
You can do the following to remove all the containers:
```sh
ansible-playbook -i hosts run_script_on_all.yml --extra-vars "op=remove"
```

You can then delete all the files that were moved there:
```sh
ansible-playbook -i hosts delete.yml
```
