import json
import logging
import urllib.parse
import urllib.request
from typing import Any, Dict, Union, List

# logging.basicConfig(level=logging.DEBUG)

from ansible.inventory.data import InventoryData
from ansible.parsing.dataloader import DataLoader
from ansible.plugins.inventory import BaseInventoryPlugin, Constructable, Cacheable

DOCUMENTATION = r"""
    name: latitudesh
    plugin_type: inventory
    short_description: Latitude.sh Dynamic Inventory
    extends_documentation_fragment:
        - inventory_cache
        - constructed
    options:
        latitudesh_projects:
            type: list
            required: True
        latitudesh_api_key:
            description: Latitude.sh API Key
            type: string
            env:
                - name: LATITUDE_API_KEY
"""
class InventoryModule(BaseInventoryPlugin, Constructable, Cacheable):
    NAME = 'latitudesh'  # used internally by Ansible, it should match the file name but not required

    def verify_file(self, path):
        '''return true/false if this is possibly a valid file for this plugin to consume'''
        valid = False
        if super(InventoryModule, self).verify_file(path):
            # Base class verifies that the file exists and is readable
            # Accept any filename with a valid inventory extension; the
            # 'plugin' key in the file is validated during parse()
            import os
            _, ext = os.path.splitext(path)

            if ext in ('.yml', '.yaml', '.json'):
                valid = True
        return valid

    def parse(self, inventory: InventoryData, loader: DataLoader, path: str, cache: bool =True):
        # Ensure properties are available via the helper methods
        super(InventoryModule, self).parse(inventory, loader, path, cache)
        
        config = self._read_config_data(path)

        tags = self.get_tags()
        
        for tag in tags:
            inventory.add_group(tag)

        servers = self.get_servers()
        for server in servers:
            self.add_server(inventory, server)

    def get_servers(self):
        latitudesh_projects = self.get_option("latitudesh_projects")
        latitudesh_api_key = self.get_option("latitudesh_api_key")

        url = "https://api.latitude.sh/servers"

        headers = {
          "Accept": "application/json",
          "Authorization": latitudesh_api_key
        }

        all_servers = []
        
        for project in latitudesh_projects:
            page_num = 1
            page_size = 20
            params = {
              "filter": {
                "project": project
              },
              "page": {
                "size": 20,
                "number": 1
              }
            }
    
            while True:
                servers = http_get_json(url, headers, params=flatten_params_dict(params)).get("data", [])
                if not servers:
                    break
                
                all_servers += servers
                params["page"]["number"] += 1
        
        return all_servers

    def get_tags(self):
        latitudesh_api_key = self.get_option("latitudesh_api_key")

        url = "https://api.latitude.sh/tags"

        headers = {
          "Accept": "application/json",
          "Authorization": latitudesh_api_key
        }

        # Tags are account level, so we don't need to filter by project
        all_tags = [tag["attributes"]["name"] for tag in http_get_json(url, headers).get("data", [])]
        
        return all_tags

    def add_server(self, inventory, server):
        attributes = server["attributes"]
        
        hostname = attributes["hostname"]
        primary_ipv4 = attributes["primary_ipv4"]

        groups = [t["name"] for t in attributes["tags"]]

        for group in groups:
            if group:
                inventory.add_host(hostname, group=group)
            else:
                inventory.add_host(hostname)

        inventory.add_host(hostname)

        host_vars = {}
        host_vars["server_name"] = hostname
        host_vars["ansible_ssh_user"] = "ubuntu"
        host_vars["ansible_ssh_host"] = primary_ipv4
        host_vars["public_ip_address"] = primary_ipv4

        for var_name, var_value in host_vars.items():
            inventory.set_variable(hostname, var_name, var_value)

        strict = self.get_option("strict")

        self._set_composite_vars(
            self.get_option("compose"), host_vars, hostname, strict=True
        )

        # The following two methods combine the provided variables dictionary with the latest host variables
        # Using these methods after _set_composite_vars() allows groups to be created with the composed variables
        self._add_host_to_composed_groups(
            self.get_option("groups"), host_vars, hostname, strict=strict
        )
        self._add_host_to_keyed_groups(
            self.get_option("keyed_groups"), host_vars, hostname, strict=strict
        )


def http_get_json(url: str, headers: Dict[str, str], params: Dict[str, Any] = None) -> Dict[str, Any]:
    """GET a JSON document using only the standard library (raises on HTTP errors)."""
    if params:
        url = f"{url}?{urllib.parse.urlencode(params, doseq=True)}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=10) as res:
        return json.load(res)


def flatten_params_dict(params: Dict[str, Any]) -> Dict[str, Union[str, List[str]]]:
    """
    Flatten nested dict/list into a single-level dict using bracket notation.
    Preserves all values: if a key repeats, its values are collected in a list.
    
    Example:
      {"foo": {"bar": "abc"}} -> {"foo[bar]": "abc"}
      {"a": [1, 2]} -> {"a[]": ["1", "2"]}
    """
    flat: Dict[str, Union[str, List[str]]] = {}

    def _recurse(prefix: str, value: Any):
        if isinstance(value, dict):
            for k, v in value.items():
                new_prefix = f"{prefix}[{k}]" if prefix else k
                _recurse(new_prefix, v)
        elif isinstance(value, (list, tuple)):
            for item in value:
                new_prefix = f"{prefix}[]"
                _recurse(new_prefix, item)
        else:
            val = "" if value is None else str(value)
            if prefix in flat:
                # If existing value is not a list, convert it
                if not isinstance(flat[prefix], list):
                    flat[prefix] = [flat[prefix]]
                flat[prefix].append(val)
            else:
                flat[prefix] = val

    _recurse("", params)
    return flat
