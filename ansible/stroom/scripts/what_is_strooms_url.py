from utils import get_inventory, get_service_fqdn
from colorama import Fore, Back, Style

service_fqdn = get_service_fqdn(get_inventory())
stroom_url = f"https://{service_fqdn}"
print(f"You can get to this Stroom deployment by going here: {Fore.GREEN}{stroom_url}/")
