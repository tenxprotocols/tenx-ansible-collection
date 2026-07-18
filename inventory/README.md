# Ansible Collection - tenx.inventory

Dynamic inventory plugin for Latitude.sh.

## Usage

```yaml
# latitudesh.yml
plugin: tenx.inventory.latitudesh
latitudesh_projects:
  - proj_XXXXXXXXXXXXX
```

The API key is read from the `LATITUDE_API_KEY` environment variable
(or `latitudesh_api_key`).

## Behavior

- Every server is added by hostname with `ansible_ssh_host` set to its
  primary IPv4 (`ansible_ssh_user: ubuntu`).
- Every Latitude tag becomes an Ansible group verbatim.
- Tags of the form `key__value` are parsed (split on the first `__`) into:
  - `latitudesh_tags` — dict host var, e.g. `{"env": "prod"}`
  - `latitudesh_datadog_tags` — list of `key:value` strings, prefixed with
    `provider:latitude`; consumed by the baseline software role as
    `DD_EXTRA_TAGS`.

See [docs/tagging.md](../docs/tagging.md) for the tag registry and format
rules.
