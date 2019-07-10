#!/usr/bin/env python
import itertools as it
from shutil import copyfile
import os


def extract_hosts_from_inventory(hosts_path):
    """Parses the hosts file at hosts_path and returns a dict"""

    inventory = {}
    with open(hosts_path) as hosts_file:
        current_host_group = ''
        for count, line in enumerate(hosts_file):
            # If we find a '[' then we've found a hosts group header
            if '[' in line:
                current_host_group = line.strip()[1:-1]
                inventory.update({current_host_group: []})
            else:
                if line.strip():
                    host_group = inventory[current_host_group]
                    host_group.append(line.strip());
                    inventory[current_host_group] = host_group
    return inventory


def convert_host_list_to_string(hosts, port):
    value = ''
    for count, host in enumerate(hosts):
        plain_host = host.split('@')[1]
        value += '    server {}:{};'.format(plain_host, port)
        if count < len(hosts) - 1:
            value += '\n'
    return value

    
def add_to_generated(generated_path, target, hosts_value):
    with open(generated_path) as f:
        new_file_string=f.read().replace(target, hosts_value)
    with open(generated_path, "w") as f:
        f.write(new_file_string)


def main():
    hosts_path = '../stroom_test_hosts'
    inventory = extract_hosts_from_inventory(hosts_path)

    if not os.path.exists('generated'):
        os.mkdir('generated')

    target = 'generated/upstreams.stroom.conf'
    copyfile('upstreams.stroom.conf.template', target)
    hosts_value = convert_host_list_to_string(inventory['strooms'], 8080)
    add_to_generated(target, '<<<STROOM_STICKY_UPSTREAMS>>>', hosts_value)
    add_to_generated(target, '<<<STROOM_UPSTREAMS>>>', hosts_value)

    target = 'generated/upstreams.auth.conf'
    copyfile('upstreams.auth.conf.template', target)
    hosts_value = convert_host_list_to_string(inventory['services'], 9443)
    add_to_generated(target, '<<<AUTH_STICKY_UPSTREAMS>>>', hosts_value)
    add_to_generated(target, '<<<AUTH_UI_UPSTREAMS>>>', hosts_value)

    target = 'generated/upstreams.proxy.conf'
    copyfile('upstreams.proxy.conf.template', target)
    hosts_value = convert_host_list_to_string(inventory['services'], 9443)
    add_to_generated(target, '<<<_UPSTREAMS>>>', hosts_value)


main()
