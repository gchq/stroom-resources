"""Extracts environment variables from the passed file and outputs
 them to a script for exporting. I know this is easier in bash but
 I wanted to keep these tools consistently in python."""

import re
import os

def write_out_vars(output_file, var_dict):
    """Writes out vars to the out put file"""
    for var_key in var_dict:
        output_file.write('export {}={}\n'.format(var_key, var_dict[var_key]))
    output_file.write('\n')

def write_out_script(stack_name):
    """Writes out a start script, based on the supplied stack name.
    The stack name must have a corresponding .yml file."""
    input_file_name = stack_name + '.yml'
    with open(input_file_name) as infile:
        host_vars_map = {}
        # host_vars = set()
        tag_vars = set()
        repo_vars = set()
        other_vars = set()
        for line in infile:
            if '${' in line:
                line = re.sub('.*{', '', line)
                line = re.sub('}.*', '', line)
                line = line.replace('\n','')
                # print(line)
                # line = re.sub(':.*', '', line)
                if 'HOST' in line:
                    pair = line.split(':-')
                    if(pair[0] not in host_vars_map):
                        host_vars_map[pair[0]] = pair[1]
                        # print(host_vars_map[pair[0]])
                    # if line not in host_vars:
                        # host_vars.add(line)
                elif 'TAG' in line:
                    if line not in tag_vars:
                        tag_vars.add(line)
                elif 'REPO' in line:
                    if line not in repo_vars:
                        repo_vars.add(line)
                elif line not in other_vars:
                    other_vars.add(line)

    # host_vars = sorted(host_vars)
    # host_vars_map = sorted(host_vars_map)
    # print(host_vars_map)
    tag_vars = sorted(tag_vars)
    repo_vars = sorted(repo_vars)
    other_vars = sorted(other_vars)

    output_script_name = stack_name + '.sh'

    with open(output_script_name, 'w') as outfile:
        write_out_vars(outfile, host_vars_map)
        # write_out_vars(outfile, tag_vars)
        # write_out_vars(outfile, repo_vars)
        # write_out_vars(outfile, other_vars)
        outfile.write('docker stack deploy --compose-file ' + output_script_name )

    # TODO: Need to checkout for existing sh file. Need to get defaults from existing
    # file, (from YAML first!). Then need to present a question for each env var,
    # also presenting the default as an option. Then we can write out something
    # that already has sensible values and is ready to run, kinda.

    os.chmod(output_script_name, 0o755)