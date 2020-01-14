# stroom-ansible

This directory contains the ansible scripts necessary for setting up a multi-node Stroom v6.0.

## Assumptions and caveats

- You have a number of machines available. a minimum of 3. You might have created these using the ansible scripts in `../aws`.
- These machines don't have any firewalls running.
- You're using the following host groups/stacks: `stroom_and_proxy`, `stroom_services`, `stroom_dbs`.

These will change as the ansible scripts evolve.

This has been tested on AWS. The AMI used is `ami-0ff760d16d9497663`, a Centos 7.0 image.

## Getting the Ansible scripts

```sh
git clone https://github.com/gchq/stroom-resources
```

The ansible scripts are in `stroom-resources/ansible`.

 
## Updating the inventory

The location of the Ansible inventory file is defined in `ansible.cfg`. If you're using aws you can use the aws playbooks (also in this repository) to create your hosts and generate this file, otherwise you'll need to write it yourself, put it somewhere sensible, and update `ansible.cfg` with that location.

The inventory should look something like this, but with <user> and <host> filled in with those values.

``` bash
[stroom_and_proxy]
<user>@<host>
<user>@<host>
[stroom_dbs]
<user>@<host>
[stroom_services]
<user>@<host>
<user>@<host>
```

## Installing Stroom

The following will do quite a lot. It will install the dependencies on the hosts, create the Stroom config based on your inventory, download the stack specified in `variables.yml`, push the stack to the hosts, set the services to run on each host, and start up stroom.
``` bash
ansible-playbook setup_all.yml
```

## Accessing stroom
Run the following to get the host to use as the entry point to stroom:

``` bash
python3 scripts/what_is_strooms_url.py
```

## Controlling the stacks

A Stroom stack has several scripts to control it. 
 - To start and stop: start/stop/restart
 - To get information about the stack: health/info/show_config/logs/status
 - To clean up: remove

NB/TODO: logs doesn't work very well because it tails and doesn't complete.

If you want to execute these on all stacks do the following:
```sh
ansible-playbook -i hosts run_script_on_all_prompt.yml
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

## Going further
There are a variety of ansible and python scripts in this directory. If your find yourself regularly restarting, say, stroom_services, then you might want to use the existing roles to create a new playbook for just doing that. If you feel tempted to create bash scripts to tie some of these operations together then be aware you can and should look to ansible first.
