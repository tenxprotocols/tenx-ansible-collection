# TenX Baseline Collection

Ansible collection for baseline server configuration with terminal support and security hardening.

## Overview

The `tenx.baseline` collection provides a standardized baseline configuration for all servers, including:
- **Ghostty Terminal Support**: Installs Ghostty terminfo for terminal compatibility
- **OS Hardening**: Applies security hardening to the operating system using DevSec standards
- **SSH Hardening**: Secures SSH configuration using DevSec best practices
- **Local Users for NetBird SSH**: local accounts with pinned UIDs; auth and Google-group authorization happen in NetBird (see [roles/users](roles/users/README.md))
- **NetBird Client**: installs the NetBird client and enrolls the host as a peer, with native SSH enabled (see [roles/netbird](roles/netbird/README.md))

## Requirements

- Ansible 2.9 or higher
- Target systems: Linux (Debian/Ubuntu, RHEL/CentOS)

## Dependencies

This collection depends on:
- `tenx.install` - For Ghostty terminal installation
- `devsec.hardening` - For security hardening roles

## Installation

1. Install the baseline collection and its dependencies:

```bash
ansible-galaxy collection install tenx.baseline
```

2. Install the required external collections:

```bash
ansible-galaxy collection install devsec.hardening
```

Or install all dependencies using a requirements file:

```yaml
# requirements.yml
collections:
  - name: tenx.baseline
  - name: devsec.hardening
    version: '>=8.0.0'
```

```bash
ansible-galaxy collection install -r requirements.yml
```

## Usage

### Basic Usage

Apply the baseline configuration to all hosts:

```bash
ansible-playbook tenx.baseline.site
```

**Note:** The baseline playbook uses a run-once mechanism. After successful completion, it creates a marker file at `/etc/tenx-baseline-applied` and will skip execution on subsequent runs. This prevents lengthy baseline configurations from running unnecessarily.

### With Inventory

```bash
ansible-playbook -i inventory/hosts tenx.baseline.site
```

### Target Specific Hosts

By default, the baseline playbook targets all hosts. To run against specific hosts or groups:

```bash
ansible-playbook tenx.baseline.site -e target_hosts=webservers
```

Or target a specific host:

```bash
ansible-playbook tenx.baseline.site -e target_hosts=web01.example.com
```

You can also use patterns:

```bash
ansible-playbook tenx.baseline.site -e target_hosts='web*'
```

### Force Re-run

To force the baseline to run even if it has already been applied:

```bash
ansible-playbook tenx.baseline.site -e baseline_force=true
```

Or in your playbook:

```yaml
- name: Force baseline re-application
  hosts: all
  vars:
    baseline_force: true
  ansible.builtin.import_playbook: tenx.baseline.site
```

### Check Baseline Status

To check if baseline has been applied on a host:

```bash
ansible all -m stat -a "path=/etc/tenx-baseline-applied"
```

### Remove Baseline Marker

To reset the baseline marker (next run will re-apply):

```bash
ansible all -b -m file -a "path=/etc/tenx-baseline-applied state=absent"
```

### Example Playbook

```yaml
---
- name: Apply baseline configuration
  hosts: all
  become: true

  roles:
    - role: tenx.install.ghostty
    - role: devsec.hardening.os_hardening
    - role: devsec.hardening.ssh_hardening
```

### Custom Variables

You can customize the hardening behavior by setting variables. See the [devsec.hardening documentation](https://galaxy.ansible.com/devsec/hardening) for available options.

Example:

```yaml
---
- name: Apply baseline with custom settings
  hosts: all
  become: true
  vars:
    os_security_suid_sgid_enforce_whitelist: true
    ssh_allow_tcp_forwarding: false

  roles:
    - role: tenx.install.ghostty
    - role: devsec.hardening.os_hardening
    - role: devsec.hardening.ssh_hardening
```

## Included Playbooks

- `site.yml` - Main playbook that applies all baseline configurations
- `ping.yml` - Connectivity check that pings every inventory host; useful for verifying dynamic inventory (e.g. from Semaphore UI) before running the baseline

## User accounts

The `users` role creates local accounts (defined in inventory `group_vars`/`host_vars`, see [roles/users/README.md](roles/users/README.md)); SSH access is authenticated and authorized by NetBird against Google.

## NetBird Setup Key

The `netbird` role enrolls each host as a NetBird peer. First-time
enrollment needs `netbird_setup_key`, which defaults to the `NB_SETUP_KEY`
environment variable, and the management server URL comes from
`netbird_management_url` / `NB_MANAGEMENT_URL` (empty targets NetBird
cloud; set it for a self-hosted server). In Semaphore UI add both to the
template's Environment (`NB_SETUP_KEY` as a secret). Hosts that are already
enrolled skip enrollment, so the key is only consulted for new peers.

## Datadog API Key

The `software` role requires `baseline_datadog_api_key`. It defaults to the `DD_API_KEY` environment variable, so in Semaphore UI add `DD_API_KEY` to the template's Environment (as a secret). Alternatively pass it as an extra variable:

```bash
ansible-playbook tenx.baseline.site -e baseline_datadog_api_key=YOUR_KEY
```

## License

MIT

## Author

TenX Protocols Infrastructure Team
