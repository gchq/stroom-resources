from utils import get_inventory, get_service_fqdn, remove_line_from_file, replace_line
import fileinput
from colorama import Fore, Back, Style
import sys


def main():
    path_to_stack = sys.argv[1]
    inventory = get_inventory()
    fqdn = get_service_fqdn(inventory)
    server_name_directive = "server_name "
    server_name_line = f'{server_name_directive} {fqdn};\n'
    server_conf_file = f"{path_to_stack}/volumes/nginx/conf/server.conf.template"
    print(f"Replacing the {Fore.GREEN}{server_name_directive}{Style.RESET_ALL} line in {Fore.GREEN}{server_conf_file}{Style.RESET_ALL} with {Fore.BLUE}{server_name_line}{Style.RESET_ALL}")
    replace_line(server_conf_file, server_name_directive, server_name_line)
    
main()
