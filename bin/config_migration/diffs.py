#!/usr/bin/env python
"""Get the difference between Stroom release configurations

Usage: diffs.py <from_release> <to_release> 
"""
import shutil
import os
import urllib
import tarfile
from docopt import docopt

def create_build_dir(build_dir):
    shutil.rmtree(build_dir, True)
    os.mkdir(build_dir)

def get_release(release_name, build_dir):
    GITHUB_DOWNLOAD_URL="https://github.com/gchq/stroom-resources/releases/download/{0}/{0}.tar.gz"
    url = GITHUB_DOWNLOAD_URL.format(release_name)
    downloaded_file="{0}/{1}.tar.gz".format(build_dir, release_name)
    extracted_files="{0}/{1}".format(build_dir, release_name)
    urllib.urlretrieve (url, downloaded_file)
    tar = tarfile.open(downloaded_file)
    tar.extractall(extracted_files)
    tar.close()

def get_path_to_config(release_name, build_dir):
    from_version_path  = "{0}/{1}/stroom_core/{1}/config/stroom_core.env".format(build_dir, release_name) 
    return from_version_path

def extract_variables_from_env_file(path):
    env_file = open(path)
    lines = env_file.readlines()
    env_vars = {}
    for line in lines:
      # Strip 'export ' and rstrip off the carriage return
      stripped = line[7:].rstrip()
      # Split on the first '=' only
      splitted = stripped.split("=", 1)
      # If an env var value has " we want to strip them
      splitted[1] = splitted[1].strip('"')

      if splitted[0] in env_vars:
        print "Warning: found repeated var:", splitted[0], "is", env_vars[splitted[0]], "and", splitted[1]
      else: 
        env_vars[splitted[0] ]= splitted[1]
    return env_vars

def setup_release(release_name, build_dir):
    get_release(release_name, build_dir)
    path = get_path_to_config(release_name, build_dir)
    env_vars = extract_variables_from_env_file(path)
    return env_vars

def compare(from_vars, to_vars):
    removed_vars = {}
    for from_var in from_vars:
      if from_var not in to_vars:
        removed_vars[from_var] = from_vars[from_var]

    added_vars = {}
    changed_vars = []
    for to_var in to_vars:
      if to_var not in from_vars:
        added_vars[to_var] = to_vars[to_var]
      else:
        if to_vars[to_var] != from_vars[to_var]:
          changed_vars.append((to_var, from_vars[to_var], to_vars[to_var]))
    return (added_vars, removed_vars, changed_vars)

def create_output_file(from_release, to_release, comparisons, build_dir):
    added_vars = comparisons[0]
    removed_vars = comparisons[1]
    changed_vars = comparisons[2]
    output = open("{0}/{1}_to_{2}.md".format(build_dir, from_release, to_release), 'w')
    output.write("# Differences between {0} and {1}\n\n".format(from_release,to_release))
    
    output.write("## Added\n\n")
    for added_var in sorted(added_vars):
      output.write("{0}={1}\n".format(added_var, added_vars[added_var]))

    output.write("\n## Removed\n\n")
    for removed_var in sorted(removed_vars):
      output.write("{0}={1}\n".format(removed_var, removed_vars[removed_var]))

    output.write("\n## Changed default values\n\n")
    for changed_var in changed_vars:
      output.write("{0} has changed from \"{1}\" to \"{2}\"".format(changed_var[0], changed_var[1], changed_var[2]))

    output.close()

def main():
    arguments = docopt(__doc__, version='Get the difference between Stroom release configurations')
    from_release = arguments["<from_release>"]
    to_release = arguments["<to_release>"]

    BUILD_DIR="./build"
    create_build_dir(BUILD_DIR)

    from_vars = setup_release(from_release, BUILD_DIR)
    to_vars = setup_release(to_release, BUILD_DIR)
    
    comparisons = compare(from_vars, to_vars)    
    create_output_file(from_release, to_release, comparisons, BUILD_DIR)

if __name__ == '__main__':
    main()
