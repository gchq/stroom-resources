"""
Functions used in several other files
"""
from tempfile import mkstemp
from shutil import move
from os import fdopen, remove
import subprocess
import json


def get_inventory():
    out = subprocess.Popen(
        ['ansible-inventory', '--list'],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout, stderr = out.communicate()
    inventory = json.loads(stdout)
    return inventory


def get_service_fqdn(inventory):
    # We'll use the first services host as the fqdn. YMMV.
    host_line = inventory["stroom_services"]["hosts"][0]
    fqdn = host_line.split('@')[1]
    return fqdn


def get_db_fqdn(inventory):
    # We'll use the first database host as the fqdn. YMMV.
    host_line = inventory["stroom_dbs"]["hosts"][0]
    fqdn = host_line.split('@')[1]
    return fqdn

def remove_line_from_file(path, line_contents):
    with open(path, "r") as f:
        lines = f.readlines()
    with open(path, "w") as f:
        for line in lines:
            if line_contents not in line:
                f.write(line)


def replace_line(file_path, substring_to_find, new_line):
    temp_file, temp_file_path = mkstemp()
    with fdopen(temp_file,'w') as new_file:
        with open(file_path) as old_file:
            for line in old_file:
                if substring_to_find in line:
                    new_file.write(new_line)
                else:
                    new_file.write(line)

    remove(file_path)
    move(temp_file_path, file_path)
