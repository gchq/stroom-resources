"""
Fetches public keys from github and concatenates them into authorized_keys.

The first argument is the path of the authorized_keys file to write to.

Subsequent arguments are treated as github usernames with corresponding keys.
"""
import os
import sys
import urllib.request


def main():
    # First make sure we've got a file to write to
    authorized_keys_path = sys.argv[1]
    if os.path.exists(authorized_keys_path):
        os.remove(authorized_keys_path)
    authorized_keys_file = open(authorized_keys_path, "a+")

    # Loop over the remaining arguments, assuming they're github usernames
    # and grab the corresponding keys file from github and write it to
    # the file (we need to decode it from bytes).
    for username in sys.argv[2:]:
        url = f'https://github.com/{username}.keys'
        response = urllib.request.urlopen(url)
        keys = response.read()
        authorized_keys_file.write(keys.decode("utf-8"))

main()
