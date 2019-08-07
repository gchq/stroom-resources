# Ansible scripts to set up AWS 

You can use these scripts and configurations to set up an AWS ansible environment for Stroom. 

## I'm part of the Stroom team. How do I set everything up?
Just run:
``` bash
ansible-playbook -v inventory setup_everything.yml
```
You'll need the vault password to be present in `~/.ansible/aws_vault_password_file`.


## Why do we write out an inventory file instead of loading the AWS instances in to an in-memory Ansible inventory?
Because that would couple the AWS and Stroom management playbooks. The Stroom management playbooks are platform agnostic.


## I'm getting access problems, what do I do?
Your access keys might have expired and you might need to update them in your config. Use the following the edit the encrypted file:
```
ansible-vault edit vars/aws_vault.yml
```

You'll need to update the obvious bits. 


## I'm not part of the Stroom team and don't have the password for the vault! How do I use these playbooks?

You'll need to create your own vault to store your secrets! 

Delete `vars/aws_vaut.yml` and run the following the edit a new file.

``` bash
ansible-vault edit vars/aws_vault.yml
```

Paste in the values from `vars/aws_vault.template.yml` and edit them for your AWS setup.

You'll need to configure the password somewhere. We do this by adding a file containing the password to `~/.ansible/aws_vault_password_file`. This is configured in `ansible.cfg`.


## I'm still getting access issues!
The playbooks will create a key_pair based on your machine name. It'll put the key that's returned from this operation into `~/.ssh/<machine name>.pem`. This is your only chance to capture the key and if it's lost you'll need to re-create the key pair. If you've any problems surrounding this then the best thing to do is probably just re-create the key pair. You can do that like this:

``` bash
ansible-playbook -i inventory recreate_key_pair.yml
```

