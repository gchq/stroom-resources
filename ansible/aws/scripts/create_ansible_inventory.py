# Converts a csv file of hosts to an ansible inventory file.
# Expects the csv file to be like:
#   <instance_tag_type>,<instance_tag_name>,<public_dns_name>
# E.g.
#   stroom_services,stroom_services_1,ec2.somewhere.in.the.world
#
# The first param must be the path to the input file.
# The second param must be the location of the output file.

import sys
import os.path
from collections import defaultdict


def parse_aws_inventory(path_to_inventory):
    inventory = defaultdict(list)
    file = open(path_to_inventory, "r")
    for line in file:
        parts = line.split(',')
        inventory[parts[0]].append(parts[2])
    return inventory   


def write_inventory_to_file(inventory, output_file):
   file = open(output_file, "w")
   for host_group in inventory.keys():
       host_group_header = f"[{host_group}]\n"
       file.write(host_group_header)
       hosts = inventory[host_group]
       for host in hosts:
           host_line = f"centos@{host}"
           file.write(host_line)
   file.close;

    
def main():
    if len(sys.argv) != 3:
        print('Expecting two argument -- the location of the aws_inventory.csv file and where to write the output inventory file.')
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        if os.path.exists(input_file) is False:
            print(f"No file at {input_file} exists!")
        else:
            print(f"Using {input_file} to generate {output_file}")
            inventory = parse_aws_inventory(input_file)
            write_inventory_to_file(inventory, output_file)


main();
