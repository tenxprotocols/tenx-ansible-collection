# tenx.baseline.netbird

Installs the [NetBird](https://netbird.io/) client from the official apt
repository and enrolls the host as a peer. Together with
[tenx.baseline.users](../users/README.md) this provides the fleet's SSH
access path: people connect over NetBird native SSH, authenticated by
Google and authorized by NetBird access policies.

By default the role targets a plain server peer. It works against NetBird
cloud or a self-hosted management server — set `netbird_management_url`
(or export `NB_MANAGEMENT_URL`) to point at an existing self-hosted server.

## What it does

1. Adds the official apt repository (`pkgs.netbird.io/debian stable main`),
   using the same key/source locations as NetBird's quickstart guide so
   manually-installed hosts converge without conflicting apt sources.
2. Installs the `netbird` package and ensures the service is running.
3. If the peer is not yet enrolled (`netbird status` reports `NeedsLogin`
   or `LoginFailed`), runs `netbird up` with the setup key, management URL,
   and `--allow-server-ssh`, then verifies the management connection.

Enrollment only happens once: already-enrolled peers are left untouched, so
the role is safe to re-run and safe on hosts that joined the network before
this role existed. The setup key is only required for that first enrollment.

## Variables

| Variable | Default | Description |
|---|---|---|
| `netbird_setup_key` | `$NB_SETUP_KEY` | setup key from the management dashboard; required only for first enrollment |
| `netbird_management_url` | `$NB_MANAGEMENT_URL` | management server URL; empty uses NetBird cloud. Set for self-hosted, e.g. `https://netbird.example.com:443` |
| `netbird_join` | `true` | enroll the host as a peer; `false` installs the client only |
| `netbird_allow_ssh` | `true` | pass `--allow-server-ssh` so NetBird's SSH server can serve logins |
| `netbird_up_extra_args` | `[]` | extra arguments for `netbird up`, e.g. `["--hostname", "web01"]` |
| `netbird_package_state` | `present` | set `latest` to upgrade the client on every run |
| `netbird_repo_url` | `https://pkgs.netbird.io/debian` | apt repository URL |
| `netbird_repo_key_url` | `.../public.key` | apt signing key URL |
| `netbird_keyring_path` | `/usr/share/keyrings/netbird-archive-keyring.gpg` | dearmored keyring location (quickstart default) |
| `netbird_service_enabled` | `true` | enable the netbird service at boot |
| `netbird_service_state` | `started` | desired service state |

## Examples

Enroll against a self-hosted management server:

```yaml
- hosts: all
  become: true
  roles:
    - role: tenx.baseline.netbird
      vars:
        netbird_management_url: "https://netbird.example.com:443"
        netbird_setup_key: "{{ vault_netbird_setup_key }}"
```

Install the client without joining (e.g. enroll manually later):

```yaml
- hosts: all
  become: true
  roles:
    - role: tenx.baseline.netbird
      vars:
        netbird_join: false
```

In Semaphore UI, add `NB_SETUP_KEY` (secret) and `NB_MANAGEMENT_URL` to the
template's Environment — no playbook changes needed.
