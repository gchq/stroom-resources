from utils import get_inventory
import sys


UPSTREAMS = {
    "auth_service":"{}/upstreams.auth.service.conf.template",
    "auth_ui":"{}/upstreams.auth.ui.conf.template",
    "proxy":"{}/upstreams.proxy.conf.template",
    "stroom_processing":"{}/upstreams.stroom.processing.conf.template",
    "stroom_ui":"{}/upstreams.stroom.ui.conf.template",
    }


def open_files_for_writing(services, path_to_nginx_conf):
    files = []
    for service in services:
        files.append(open(UPSTREAMS[service].format(path_to_nginx_conf), "w"))
    return files


def write_upstream_file(hosts, open_files):
    for open_file in open_files:
        for ansible_host in hosts:
           host = ansible_host.split('@')[1]
           open_file.write(f"server {host}:8099;\n")
        open_file.close()


def main():
    path_to_stack = sys.argv[1]
    path_to_nginx_conf = f"{path_to_stack}/volumes/nginx/conf"
    inventory = get_inventory()

    write_upstream_file(
        inventory["stroom_services"]["hosts"],
        open_files_for_writing(['auth_service', 'auth_ui'], path_to_nginx_conf))
    
    write_upstream_file(
        inventory["stroom_and_proxy"]["hosts"],
        open_files_for_writing(['proxy', 'stroom_processing','stroom_ui'], path_to_nginx_conf))

main()
