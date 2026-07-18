# Host Tagging Convention

One tag convention for every hosting provider (Latitude.sh, GCP, AWS, Azure),
parseable as key/value pairs, feeding Datadog metrics/logs and Ansible
inventory groups.

## Format

- **Keys**: lowercase snake_case — `[a-z][a-z0-9_]*`, single underscores only.
- **Values**: lowercase snake_case — `[a-z0-9][a-z0-9_]*`, single underscores only.
- **`__` (double underscore) is forbidden inside keys and values** — it is the
  separator in the flat form.
- Values are small closed enumerations. No IPs, timestamps, or per-host-unique
  values (tag cardinality drives Datadog custom-metrics cost). One value per
  key per host.
- Add new keys/values to this document before using them.

This charset is simultaneously valid as a GCP label (the strictest format),
an AWS/Azure tag, a Datadog tag, and an Ansible group name.

## Per-provider storage

| Provider | Storage | How it reaches Datadog |
|---|---|---|
| Latitude.sh | flat tag `key__value` (split on the FIRST `__`) | `tenx.inventory.latitudesh` parses tags into `latitudesh_datadog_tags`; the baseline software role writes them to `DD_EXTRA_TAGS` |
| AWS / Azure | native key/value tags | Datadog cloud integration imports them |
| GCP | native labels | Datadog GCP integration imports them |

On Latitude, each tag also becomes an Ansible group verbatim
(e.g. `hosts: chain__tezos`), which is why values avoid hyphens.

The plugin exposes two host vars per server: `latitudesh_tags` (dict) and
`latitudesh_datadog_tags` (list of `key:value`, prefixed with
`provider:latitude`).

## Base set — every host

| Key | Values | Notes |
|---|---|---|
| `env` | `prod`, `dev` | Datadog unified-tagging reserved key |
| `role` | `chain_node`, `inference`, `dev_box`, `k8s_node`, `monitoring`, `automation`, `vpn` | primary "what is this box" pivot |
| `team` | `infra`, `blockchain`, `ai` | ownership/routing |
| `provider` | `latitude`, `gcp`, `aws`, `azure` | injected automatically on Latitude |
| `managed_by` | `ansible`, `terraform`, `manual` | injected (`ansible`) by the baseline software role |

## Overlays

**Blockchain nodes** (`role__chain_node`)

| Key | Values |
|---|---|
| `chain` | `tezos`, `sui` |
| `chain_network` | `mainnet`, `ghostnet`, `testnet` |
| `node_type` | `baker`, `fullnode`, `archive`, `rpc` |

**Inference servers** (`role__inference`)

| Key | Values |
|---|---|
| `model` | e.g. `qwen_3_coder_next` |
| `accelerator` | GPU SKU, e.g. `h100`, `a100` |

**Dev boxes** (`role__dev_box`)

| Key | Values |
|---|---|
| `owner` | username, e.g. `geoff` |
| `accelerator` | GPU SKU or `none` |

**Kubernetes nodes** (`role__k8s_node`)

| Key | Values |
|---|---|
| `cluster` | cluster name |
| `k8s_role` | `control_plane`, `worker` |

## Examples (Latitude tags)

Shared vLLM inference server:
`env__prod`, `role__inference`, `team__ai`, `model__qwen_3_coder_next`

Dev box:
`env__dev`, `role__dev_box`, `team__infra`, `owner__geoff`

Tezos mainnet baker:
`env__prod`, `role__chain_node`, `team__blockchain`, `chain__tezos`,
`chain_network__mainnet`, `node_type__baker`
