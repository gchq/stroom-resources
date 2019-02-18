#!/usr/bin/env python
"""Creates an override file based on a large .env file.
The existing stacks ship with very large .env files. These files
duplicate all of the defaults in the .yml files. We have realised
that this makes reading the .env file quite over-whelming. The 
.env file doesn't need to export anything that isn't different
from the yaml. This script will create a new env file that only
includes exports for things that are different to the settings in
the yaml.

Usage: clean_env_file.py <env_file> <yaml_file>

E.g.:
./clean_env_file.py stroom_core.env stroom_core.yml
"""
import sys
import shutil
import os
import urllib
import re


def extract_variables_from_env_file(path):
    env_file = open(path)
    lines = env_file.readlines()
    env_vars = {}
    repeated_vars = []
    for line in lines:
        # Strip 'export ' and rstrip off the carriage return
        stripped = line[7:].rstrip()
        # Split on the first '=' only
        splitted = stripped.split("=", 1)
        # If an env var value has " we want to strip them
        splitted[1] = splitted[1].strip('"')

        if splitted[0] in env_vars:
            repeated_vars.append(
                 (splitted[0], env_vars[splitted[0]], splitted[1]))
        else:
            env_vars[splitted[0]] = splitted[1]
    return (env_vars, repeated_vars)


def extract_variables_from_yaml_file(yml_path):
    # First get all the lines from the file
    container_conf = open(yml_path, 'r')
    container_conf_lines = container_conf.readlines()
    container_conf.close();

    env_vars = {} 
    for line in container_conf_lines:
        results = re.findall("{(.*?)}",line)
        for result in results:
            if result is not None:
                env_var = result;
                
                # Do a bit of clean-up
                if env_var[:1] == '{':
                    env_var = env_var[1:]
                if env_var.endswith('}'):
                    env_var = env_var[:-1]

                # Finally split the line and put into the dict
                env_var_split = env_var.split(':-')
                env_vars[env_var_split[0]] = env_var_split[1]

    return env_vars


def compare_vars(env_vars, yaml_vars):
    unmatched_vars = {}
    matched_vars = {}
    for env_var in env_vars[0]:
        env_var_value = env_vars[0][env_var]

        if env_var in yaml_vars:
            yaml_value = yaml_vars[env_var]
            if yaml_value != env_var_value:
                unmatched_vars[env_var] = [env_var_value, yaml_value]
            else:
                matched_vars[env_var] = [env_var_value, yaml_value]
        else:
            print 'ERROR: Not found in yaml: {0}'.format(env_var)
    
    return unmatched_vars, matched_vars


def write_out_report(unmatched_vars, matched_vars):
    report_file = open('clean_env_file.md', 'w')
    report_file.write('# Comparison of vars in env file and yaml\n\n')

    report_file.write('## Vars that are not the same\n\n')
    report_file.write('```\n')
    for k, v in unmatched_vars.items():
        report_file.write('{0}={1}\n'.format(k,v))
    report_file.write('```\n');

    report_file.write('\n## Vars that are the same\n\n')
    report_file.write('```\n');
    for k, v in matched_vars.items():
        report_file.write('{0}={1}\n'.format(k,v))
    report_file.write('```\n');

    report_file.close()
    print 'Written out a report at ./clean_env_file.env'


def write_out_overrides(unmatched_vars):
    output = open('overrides.env', 'w')
    for k,v in unmatched_vars.items():
        output.write('export {0}=\'{1}\'\n'.format(k,v[0]))

    print 'Written out overrides at ./overrides.env'

def main():
    if len(sys.argv) is not 3:
        print """Usage: clean_env_file.py <env_file> <yaml_file>

E.g.:
./clean_env_file.py stroom_core.env stroom_core.yml
"""
    else:
        env_file = sys.argv[1]
        yaml_file = sys.argv[2]
        env_vars = extract_variables_from_env_file(env_file);
        yaml_vars = extract_variables_from_yaml_file(yaml_file)
        unmatched_vars, matched_vars = compare_vars(env_vars, yaml_vars)
        write_out_overrides(unmatched_vars)
        write_out_report(unmatched_vars, matched_vars)


if __name__ == '__main__':
    main()
