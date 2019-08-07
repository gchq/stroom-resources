from utils import get_inventory


CONF = './releases/volumes/nginx/conf'
UPSTREAMS = {
    "auth_service":f"{CONF}/upstreams.auth.service.conf.template",
    "auth_ui":f"{CONF}/upstreams.auth.ui.conf.template",
    "proxy":f"{CONF}/upstreams.proxy.conf.template",
    "stroom_processing":f"{CONF}/upstreams.stroom.processing.conf.template",
    "stroom_ui":f"{CONF}/upstreams.stroom.ui.conf.template",
    }


def open_files_for_writing(services):
    files = []
    for service in services:
        files.append(open(UPSTREAMS[service], "w"))
    return files


def write_upstream_file(hosts, open_files):
    for open_file in open_files:
        for ansible_host in hosts:
           host = ansible_host.split('@')[1]
           open_file.write(f"server {host}:8099;\n")
        open_file.close()


def main():
    inventory = get_inventory()

    write_upstream_file(
        inventory["stroom_services"]["hosts"],
        open_files_for_writing(['auth_service', 'auth_ui']))
    
    write_upstream_file(
        inventory["stroom_and_proxy"]["hosts"],
        open_files_for_writing(['proxy', 'stroom_processing','stroom_ui']))

main()
