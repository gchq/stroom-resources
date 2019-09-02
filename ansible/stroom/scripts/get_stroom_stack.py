from colorama import Fore, Back, Style
from distutils.dir_util import copy_tree
from os import listdir, symlink, remove, readlink
from pathlib import Path
from shutil import copyfile
import os
import sys
import tarfile
import tempfile
import urllib.request

if len(sys.argv) != 2:
    print(f"{Fore.RED}Please supply the stack version to download. E.g. v6.0.5")
else:
    version = sys.argv[1]
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"{Back.GREEN}{Fore.WHITE}Downloading and symlinking version {version} of Stroom{Style.RESET_ALL}")
        print(f"Using temporary directory {Fore.BLUE}{temp_dir}{Style.RESET_ALL}")


        # Download
        url = f"https://github.com/gchq/stroom-resources/releases/download/stroom-stacks-{version}/stroom_core-{version}.tar.gz"
        print(f"Downloading {Fore.BLUE}{url}")
        tar_file = f"{temp_dir}/stroom_core-{version}.tar.gz"
        urllib.request.urlretrieve(url, tar_file)
        print(f"{Style.RESET_ALL}") # wget prints progress but not a carriage return (◔_◔). We're also resetting the colour.


        # Extract
        tar = tarfile.open(tar_file)
        tar.extractall(temp_dir)
        tar.close()


        # Extract
        script_dir = os.path.dirname(os.path.realpath(__file__))
        releases_dir = f"{script_dir}/../releases"
        print(f"Copying to {Fore.BLUE}{releases_dir}{Style.RESET_ALL}")
        copied_files = copy_tree(f"{temp_dir}/stroom_core", releases_dir)

        
        # Symlink to releases/latest
        latest = f"{releases_dir}/latest"
        latest_dir = Path(latest)
        if latest_dir.exists():
            print(f"{Fore.YELLOW}WARNING:{Fore.RESET} The {Fore.BLUE}latest{Fore.RESET} symlink already exists! It currently points to {Fore.BLUE}{readlink(latest_dir)}{Style.RESET_ALL} but we'll re-create it, pointing to this release.{Style.RESET_ALL}{Style.RESET_ALL}")
            remove(latest)
        symlink(f"{releases_dir}/stroom_core-{version}", latest) 

        print(f"{Fore.GREEN}Successfully downloaded and unpacked version {Fore.BLUE}{version}{Fore.GREEN} of Stroom!{Style.RESET_ALL}")
