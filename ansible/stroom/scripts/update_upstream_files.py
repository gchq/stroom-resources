from utils import get_inventory
import sys


def write_upstream_file(hosts, path_to_file, port):
    open_file = open(f"{path_to_file}", "w")
    for ansible_host in hosts:
       host = ansible_host.split('@')[1]
       open_file.write(f"server {host}:{port};\n")
    open_file.close()

    
def main():
    path_to_stack = sys.argv[1]
    path_to_nginx_conf = f"{path_to_stack}/volumes/nginx/conf"
    inventory = get_inventory()

    service_hosts = inventory["stroom_services"]["hosts"]
    write_upstream_file(service_hosts, f"{path_to_nginx_conf}/upstreams.auth.service.conf.template", "8099")
    write_upstream_file(service_hosts, f"{path_to_nginx_conf}/upstreams.auth.ui.conf.template", "9443")

    stroom_and_proxy_hosts = inventory["stroom_and_proxy"]["hosts"]
    write_upstream_file(stroom_and_proxy_hosts, f"{path_to_nginx_conf}/upstreams.proxy.conf.template", "8090")
    write_upstream_file(stroom_and_proxy_hosts, f"{path_to_nginx_conf}/upstreams.stroom.ui.conf.template", "8080")
    write_upstream_file(stroom_and_proxy_hosts, f"{path_to_nginx_conf}/upstreams.stroom.processing.conf.template", "8080")

    
main()
