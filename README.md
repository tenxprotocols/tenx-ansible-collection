# TenX Ansible Collections

Ansible collections maintained by [TenX Protocols](https://tenx.inc) for infrastructure automation.

## Collections

| Collection | Path | Description |
|---|---|---|
| `tenx.inventory` | [`inventory/`](inventory/) | Dynamic inventory plugins, including [latitude.sh](https://www.latitude.sh/) (`tenx.inventory.latitudesh`) |
| `tenx.baseline` | [`baseline/`](baseline/) | Baseline server configuration: OS/SSH hardening, APT mirrors, Datadog agent |
| `tenx.ai` | [`ai/`](ai/) | AI inference: NVIDIA driver bring-up and vLLM model serving |

## Installation

Install straight from this repository with a `requirements.yml`:

```yaml
collections:
  - name: https://github.com/tenxprotocols/tenx-ansible-collection.git#/inventory/
    type: git
    version: main
  - name: https://github.com/tenxprotocols/tenx-ansible-collection.git#/baseline/
    type: git
    version: main
  - name: https://github.com/tenxprotocols/tenx-ansible-collection.git#/ai/
    type: git
    version: main
```

```bash
ansible-galaxy collection install -r requirements.yml
```

See each collection's README for usage.

## License

[MIT](LICENSE)
