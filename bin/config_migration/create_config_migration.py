#!/usr/bin/env python
"""Generates a manual migration between two Stroom releases

Usage: create_config_migration.py <from_release> <to_release>

E.g.:
./create_config_migration.py stroom_core-v6.0-beta.18 stroom_core-v6.0-beta.19
"""
import shutil
import os
import urllib
import tarfile
import sys
from docopt import docopt


class colours:
    RED = '\033[1;31m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    UNDERLINE = '\033[4m'
    NC = '\033[0m'
    BLUE = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


class config:
    BUILD_DIR = './build'
    OUTPUT_DIR = './migrations'


def create_build_dir():
    shutil.rmtree(config.BUILD_DIR, True)
    os.mkdir(config.BUILD_DIR)
    if not os.path.isdir(config.OUTPUT_DIR):
        os.mkdir(config.OUTPUT_DIR)

def log_error(msg):
    print "{0}Error{1}: {2}{3}".format(
            colours.RED, colours.NC, msg, colours.NC)


def get_release(release_name):
    GITHUB_DOWNLOAD_URL = "https://github.com/gchq/stroom-resources/" \
            + "releases/download/{0}/{0}.tar.gz"
    url = GITHUB_DOWNLOAD_URL.format(release_name)
    downloaded_file = "{0}/{1}.tar.gz".format(config.BUILD_DIR, release_name)
    extracted_files = "{0}/{1}".format(config.BUILD_DIR, release_name)
    print "Downloading file {0}{1}{2}" \
        .format(colours.BLUE, url, colours.NC)
    urllib.urlretrieve(url, downloaded_file)
    try:
        with tarfile.open(downloaded_file) as tar:
            tar = tarfile.open(downloaded_file)
            tar.extractall(extracted_files)
    except:
        log_error("Opening file {0}{1}{2}, the url may not exist or the file may be corrupt."
                .format(colours.BLUE, downloaded_file, colours.NC))
        raise


def get_path_to_config(release_name):
    from_version_path = "{0}/{1}/stroom_core/{1}/config/stroom_core.env" \
        .format(config.BUILD_DIR, release_name)
    return from_version_path


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


def setup_release(release_name):
    get_release(release_name)
    path = get_path_to_config(release_name)
    (env_vars, repeated_vars) = extract_variables_from_env_file(path)
    return (env_vars, repeated_vars)


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
                changed_vars.append(
                    (to_var, from_vars[to_var], to_vars[to_var]))
    return (added_vars, removed_vars, changed_vars)


def create_output_file(
       output_file_path, from_release, to_release, comparisons):
    added_vars = comparisons[0]
    removed_vars = comparisons[1]
    changed_vars = comparisons[2]
    output = open(output_file_path, 'w')
    output.write("# Differences between {0} and {1}\n\n"
                 .format(from_release, to_release))

    output.write("## Added\n\n")
    for added_var in sorted(added_vars):
        output.write("{0}={1}\n".format(added_var, added_vars[added_var]))

    output.write("\n## Removed\n\n")
    for removed_var in sorted(removed_vars):
        output.write("{0}={1}\n"
                     .format(removed_var, removed_vars[removed_var]))

    output.write("\n## Changed default values\n\n")
    for changed_var in changed_vars:
        output.write("{0} has changed from \"{1}\" to \"{2}\"\n"
                     .format(changed_var[0], changed_var[1], changed_var[2]))

    output.close()


def add_repetitions_to_output_file(
               output_file_path, release_name, repeated_vars):
    output = open(output_file_path, 'a')
    output.write(
         "\n## Variables that occur more than once within the {0} env file\n\n"
         .format(release_name))
    for repeated_var in repeated_vars:
        output.write(
                "{0} is defined twice, as \"{1}\" and as \"{2}\"\n"
                .format(repeated_var[0], repeated_var[1], repeated_var[2]))
    output.close()


def main():
    arguments = docopt(__doc__, version='v1.0')
    from_release = arguments["<from_release>"]
    to_release = arguments["<to_release>"]

    print "Comparing the environment variable files of {0}{1}{2}" \
        .format(colours.BLUE, from_release, colours.NC) \
        + ", and {0}{1}{2}".format(colours.BLUE, to_release, colours.NC)

    create_build_dir()

    output_file_path = "{0}/{1}_to_{2}.md".format(config.OUTPUT_DIR,
                                                  from_release, to_release)

    (from_vars, repeated_from_vars) = setup_release(from_release)
    (to_vars, repeated_to_vars) = setup_release(to_release)
    comparisons = compare(from_vars, to_vars)
    create_output_file(output_file_path, from_release, to_release, comparisons)

    add_repetitions_to_output_file(output_file_path, from_release,
                                   repeated_from_vars)
    add_repetitions_to_output_file(output_file_path, to_release,
                                   repeated_to_vars)

    print "A list of differences has been written to {0}{1}{2}".format(
        colours.BLUE, output_file_path, colours.NC)


if __name__ == '__main__':
    main()
