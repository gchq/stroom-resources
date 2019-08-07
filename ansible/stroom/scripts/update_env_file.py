from utils import get_inventory, get_service_fqdn, remove_line_from_file, get_db_fqdn

env_file_path = './releases/latest/config/stroom_core.env'

def prepend_line(path, line):
    file = open(path, "r+")
    content = file.read()
    file.seek(0,0)
    file.write(line.rstrip('\r\n') + '\n' + content)

def add_export_line(export_text, fqdn):
    export_line = f"{export_text}={fqdn}"
    remove_line_from_file(env_file_path, f"{export_text}=")
    prepend_line(env_file_path, export_line)
    
def main():
    inventory = get_inventory()

    add_export_line('export HOST_IP', get_service_fqdn(inventory))
    add_export_line('export DB_HOST_IP', get_db_fqdn(inventory))

main()
