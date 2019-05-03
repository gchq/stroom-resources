#!/usr/bin/env python3
"""

Usage: create_config_migration.py <from_release> <to_release> <stack_name>

E.g.:
./create_config_migration.py stroom-stacks-v6.0-beta.30 stroom-stacks-v6.0-beta.31 stroom_core
"""
import os
import re
import shutil
import sys
import tarfile
import urllib.request
import filecmp
import difflib

FENCE_OPEN_BASH = "```bash\n"
FENCE_OPEN_DIFF = "```diff\n"
FENCE_CLOSE = "```\n"

USAGE_TXT= "" \
        + "Script to generate a list of configuration changes between two releases\n" \
        + "Usage: create_config_migration.py <from_release> <to_release> <stack_name>\n" \
        + "E.g: \n" \
        + "./create_config_migration.py stroom-stacks-v6.0-beta.30 stroom-stacks-v6.0-beta.31 stroom_core" \


class Colours:
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


class Config:
    BUILD_DIR = './build'
    OUTPUT_DIR = './migrations'

def print_usage():
    print(USAGE_TXT)

def print_error(msg):
    print("{0}Error{1}: {2}".format(Colours.RED, Colours.NC, msg))


def create_build_dir():
    shutil.rmtree(Config.BUILD_DIR, True)
    os.mkdir(Config.BUILD_DIR)
    if not os.path.isdir(Config.OUTPUT_DIR):
        os.mkdir(Config.OUTPUT_DIR)


def log_error(msg):
    print("{0}Error{1}: {2}{3}".format(
            Colours.RED, Colours.NC, msg, Colours.NC))


def get_version_from_release(release_name):
    match = re.search("v[0-9]+\.[0-9]+.*", release_name)
    if not match:
        log_error ("Unable to extract version from {0}".format(release_name))
        exit(1)
    return match.group()


def download_release(release_name, stack_name):
    version = get_version_from_release(release_name)
    artifact = "{0}-{1}.tar.gz".format(stack_name, version)

    GITHUB_DOWNLOAD_URL = "https://github.com/gchq/stroom-resources/" \
            + "releases/download/{0}/{1}"
    url = GITHUB_DOWNLOAD_URL.format(release_name, artifact)
    downloaded_file = "{0}/{1}".format(Config.BUILD_DIR, artifact)
    extracted_files = "{0}/{1}".format(Config.BUILD_DIR, release_name)
    print("Downloading file {0}{1}{2}" \
        .format(Colours.BLUE, url, Colours.NC))
    urllib.request.urlretrieve(url, downloaded_file)
    try:
        with tarfile.open(downloaded_file) as tar:
            tar = tarfile.open(downloaded_file)
            tar.extractall(extracted_files)
    except:
        log_error("Opening file {0}{1}{2}, the url may not exist or the file may be corrupt."
                .format(Colours.BLUE, downloaded_file, Colours.NC))
        raise


def get_path_to_config(release_name, stack_name):
    version = get_version_from_release(release_name)
    from_version_path = "{0}/{1}/{2}/{2}-{3}/config/{2}.env" \
        .format(Config.BUILD_DIR, release_name, stack_name, version)
    return from_version_path


def get_path_to_volumes_dir(release_name, stack_name):
    return "{0}/{1}/{2}/volumes" \
        .format(Config.BUILD_DIR, release_name, stack_name)


def extract_variables_from_env_file(path):
    print("Extracting variables from file {0}{1}{2}" \
        .format(Colours.BLUE, path, Colours.NC))
    env_file = open(path)
    lines = env_file.readlines()
    env_vars = {}
    repeated_vars = []
    ignored_lines_regex = re.compile("(^\s*$|^\s*#.*)")
    for line in lines:
        if not ignored_lines_regex.match(line):
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


def setup_release(release_name, stack_name):
    download_release(release_name, stack_name)
    path = get_path_to_config(release_name, stack_name)
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


def write_heading_2(file_handle, heading):
    file_handle.write("## {0}\n\n".format(heading))


def write_heading_3(file_handle, heading):
    file_handle.write("### {0}\n\n".format(heading))


def create_output_file(
        output_file_path, 
        from_release, 
        to_release, 
        comparisons):
    added_vars = comparisons[0]
    removed_vars = comparisons[1]
    changed_vars = comparisons[2]
    output = open(output_file_path, 'w')
    output.write("# Differences between `{0}` and `{1}`\n\n"
                 .format(from_release, to_release))

    write_heading_2(output, "Added")
    output.write(FENCE_OPEN_BASH)
    for added_var in sorted(added_vars):
        output.write("{0}={1}\n".format(added_var, added_vars[added_var]))
    output.write(FENCE_CLOSE)

    output.write("\n")
    write_heading_2(output, "Removed")
    output.write(FENCE_OPEN_BASH)
    for removed_var in sorted(removed_vars):
        output.write("{0}={1}\n"
                     .format(removed_var, removed_vars[removed_var]))
    output.write(FENCE_CLOSE)

    output.write("\n")
    write_heading_2(output, "Changed default values")
    output.write(FENCE_OPEN_BASH)
    for changed_var in changed_vars:
        output.write("{0} has changed from \"{1}\" to \"{2}\"\n"
                     .format(changed_var[0], changed_var[1], changed_var[2]))
    output.write(FENCE_CLOSE)

    output.close()


def add_repetitions_to_output_file(
               output_file_path, release_name, repeated_vars):
    output = open(output_file_path, 'a')
    output.write("\n")
    write_heading_2(
            output,
            "Variables that occur more than once within the `{0}` env file"
            .format(release_name))
    output.write(FENCE_OPEN_BASH)
    for repeated_var in repeated_vars:
        output.write(
                "{0} is defined twice, as \"{1}\" and as \"{2}\"\n"
                .format(repeated_var[0], repeated_var[1], repeated_var[2]))
    output.write(FENCE_CLOSE)
    output.close()


def dump_file_contents(file_path):
    with open(file_path, 'r') as file_handle:
        # print file_handle.read()
        for line in file_handle:
            fence_match = re.search("^\`\`\`", line)
            if fence_match == None:
                heading_match = re.search("^#+ ", line)
                if heading_match != None:
                    print("{0}{1}{2}".format(Colours.YELLOW, line, Colours.NC), end='')
                else:
                    print(line, end='')


def diff_files(output, from_file, to_file):
    with open(from_file, 'r') as from_handle:
        with open(to_file, 'r') as to_handle:
            diff = difflib.unified_diff(
                from_handle.readlines(),
                to_handle.readlines()
            )
            for line in diff:
                output.write(line)


def compare_directories(output_file_path, from_release, to_release, stack_name):
    with open(output_file_path, 'a') as output:
        write_heading_2(output, "Changes to the volumes directory")
        from_dir = get_path_to_volumes_dir(from_release, stack_name)
        to_dir = get_path_to_volumes_dir(to_release, stack_name)
        # filecmp.dircmp(from_dir, to_dir).report_full_closure()
        dir_comp = filecmp.dircmp(from_dir, to_dir)
        changed_files=[]
        process_directory_comparison(output, dir_comp, "", changed_files) 

        for pair in changed_files:
            output.write("\n")
            write_heading_3(output, "Diff for {0}".format(pair[0]))
            output.write("From: `" + pair[1] + "`\n")
            output.write("\n")
            output.write("To:   `" + pair[2] + "`\n")
            output.write("\n")
            output.write(FENCE_OPEN_DIFF)
            diff_files(output, pair[1], pair[2])
            output.write(FENCE_CLOSE)


def process_directory_comparison(output, dir_comp, indent, changed_files):

    # Sort all the lists for a consistent output
    dir_comp.diff_files.sort()
    dir_comp.left_only.sort()
    dir_comp.right_only.sort()
    dir_comp.common_dirs.sort()

    # recursive processing of common dirs
    for name in dir_comp.common_dirs:
        output.write("{0}* {1}/\n".format(indent, name))
        process_directory_comparison(
                output, 
                dir_comp.subdirs[name], 
                indent + "    ", 
                changed_files)

    # Added directories
    for name in dir_comp.right_only:
        if os.path.isdir(dir_comp.right + "/" + name):
        # if name in dir_comp.subdirs:
            output.write("{0}* {1}/ - **ADDED**\n".format(indent, name))

    # removed directories
    for name in dir_comp.left_only:
        # if name in dir_comp.subdirs:
        if os.path.isdir(dir_comp.left + "/" + name):
            output.write("{0}* {1}/ - **REMOVED**\n".format(indent, name))

    # Modified files
    for file_name in dir_comp.diff_files:
        output.write("{0}* {1} - **MODIFIED** (see below)\n".format(indent, file_name))
        pair = (file_name, 
                dir_comp.left + "/" + file_name, 
                dir_comp.right + "/" + file_name)
        changed_files.append(pair)

    # Added files
    for name in dir_comp.right_only:
        if os.path.isfile(dir_comp.right + "/" + name):
        # if not name in dir_comp.subdirs:
            output.write("{0}* {1} - **ADDED**\n".format(indent, name))

    # Removed files
    for name in dir_comp.left_only:
        if os.path.isfile(dir_comp.left + "/" + name):
        # if not name in dir_comp.subdirs:
            output.write("{0}{1} - **REMOVED**\n".format(indent, name))


def main():
    if len(sys.argv) != 4:
        print_error("Invalid arguments")
        print_usage()
        exit(1)

    from_release = sys.argv[1]
    to_release = sys.argv[2]
    stack_name = sys.argv[3]

    print("Comparing the environment variable files of {0}{1}{2}" \
        .format(Colours.BLUE, from_release, Colours.NC) \
        + ", and {0}{1}{2}".format(Colours.BLUE, to_release, Colours.NC))

    create_build_dir()

    output_file_path = "{0}/{3}__{1}_to_{2}.md".format(
        Config.OUTPUT_DIR,
        from_release, to_release, stack_name)

    (from_vars, repeated_from_vars) = setup_release(from_release, stack_name)
    (to_vars, repeated_to_vars) = setup_release(to_release, stack_name)
    comparisons = compare(from_vars, to_vars)
    create_output_file(output_file_path, from_release, to_release, comparisons)

    add_repetitions_to_output_file(output_file_path, from_release,
                                   repeated_from_vars)
    add_repetitions_to_output_file(output_file_path, to_release,
                                   repeated_to_vars)

    compare_directories(output_file_path, from_release, to_release, stack_name)

    print("A list of differences has been written to {0}{1}{2}".format(
        Colours.BLUE, output_file_path, Colours.NC))
    print("")
    print("=====================================================================")
    dump_file_contents(output_file_path)
    print("")
    print("=====================================================================")


if __name__ == '__main__':
    main()
