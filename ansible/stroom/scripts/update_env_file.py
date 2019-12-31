from utils import get_inventory, get_service_fqdn, get_db_fqdn, remove_line_from_file
import sys

def prepend_line(path, line):
    file = open(path, "r+")
    content = file.read()
    file.seek(0,0)
    file.write(line.rstrip('\r\n') + '\n' + content)


def replace_host_ip_line(fqdn, env_file_path):
    # Remove exisiting line
    export_text = 'export HOST_IP'
    remove_line_from_file(env_file_path, f"{export_text}=")

    # Add in new line, assigning the fqdn
    host_ip_export_line = f"{export_text}={fqdn}"
    prepend_line(env_file_path, host_ip_export_line)

    
def replace_db_host_ip_line(fqdn, env_file_path):
    # Remove existing line
    existing_line = 'DB_HOST_IP=$HOST_IP'
    remove_line_from_file(env_file_path, existing_line)
    # We're also going to remove a line that might previously have been added by this script
    new_line = 'export DB_HOST_IP='
    remove_line_from_file(env_file_path, new_line)

    # Add in new line, assigning the fqdn
    export_text = 'export DB_HOST_IP'
    host_ip_export_line = f"{export_text}={fqdn}"
    prepend_line(env_file_path, host_ip_export_line)

    
def main():
    path_to_stack = sys.argv[1]
    env_file_path = f'{path_to_stack}/latest/config/stroom_core.env'
    inventory = get_inventory()
    fqdn = get_service_fqdn(inventory)
    db_fqdn = get_db_fqdn(inventory)

    replace_host_ip_line(fqdn, env_file_path)
    replace_db_host_ip_line(db_fqdn, env_file_path)


main()
