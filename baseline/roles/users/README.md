# tenx.baseline.users

Manages local user accounts with pinned UIDs so people can SSH into hosts
through [NetBird native SSH](https://docs.netbird.io/manage/peers/ssh).
Authentication and authorization live in NetBird + Google: you log in with
your Google account (OIDC/JWT) and the NetBird access policy decides which
Google groups may connect as which OS users. This role only makes those OS
users exist — no directory service, no certificates, no passwords on the
host.

## How access works

1. **Authentication** — `ssh <user>@<peer>` triggers NetBird's SSO flow
   against Google. No passwords: accounts are created locked and the role
   enforces `PasswordAuthentication no` in `sshd_config.d` (unless
   `users_enable_ssh_password_auth: true`).
2. **Authorization** — the NetBird access policy for port 22 maps source
   groups (synced from Google) to allowed OS users. Removing someone from
   the Google group locks them out at the next login attempt.
3. **Identity** — this role creates the OS accounts (with home directories
   from `/etc/skel`, created at account creation so NetBird's
   chdir-into-home works on first login) and grants sudo via a local group.

## Defining accounts

Accounts are intentionally **not** defined in role defaults. Put the
fleet-wide team in inventory `group_vars`, and use `users_accounts_extra`
in `host_vars` (or extra vars) to grant additional access on specific
hosts:

```yaml
# group_vars/all.yml — everyone, everywhere
users_accounts:
  - name: geoff
    uid: 2001
    sudo: true

# host_vars/tenx-ai-qwen-3-coder-next.yml — extra people on one host
users_accounts_extra:
  - name: alice
    uid: 2002
    groups: [docker]
```

Pin `uid`s (pick a range, e.g. 2001+) so ownership is consistent across
hosts. Supplementary groups referenced by accounts can be created via
`users_groups`.

## Variables

| Variable | Default | Description |
|---|---|---|
| `users_accounts` | `[]` | account list: `name`, `uid`, `comment`, `shell`, `groups`, `sudo` |
| `users_accounts_extra` | `[]` | appended to `users_accounts`; for host/group-level additions |
| `users_groups` | `[]` | supplementary groups to create (`name`, optional `gid`) |
| `users_absent` | `[]` | account names to remove |
| `users_absent_remove_home` | `false` | also delete removed accounts' home dirs |
| `users_default_shell` | `/bin/bash` | default login shell |
| `users_sudo_group` | `infra-admins` | local group granted NOPASSWD sudo |
| `users_sudo_group_gid` | `2000` | pinned gid for the sudo group |
| `users_enable_ssh_password_auth` | `false` | allow sshd password logins (avoid on internet-exposed hosts) |

## NetBird setup (once per network)

1. Enable the SSH server on peers: `netbird up --allow-server-ssh`.
2. In the access policy allowing port 22, configure the SSH user mapping:
   source Google group → allowed OS users. Prefer explicit user lists over
   the wildcard, which lets any authenticated NetBird user log in as any
   local account.

## Verification

```bash
id geoff                     # account exists, groups include infra-admins
ssh geoff@<peer>             # Google OIDC flow in browser, no password
sudo -l                      # NOPASSWD via /etc/sudoers.d/90-infra-admins
sudo sshd -T | grep -i passwordauthentication   # no
```

## Migrating a host from the sssd role

The earlier `tenx.baseline.sssd` role created homes under Google-assigned
UIDs. On such hosts, after the first run of this role:

```bash
sudo chown -R <user>:<user> /home/<user>     # re-own home to the local uid
sudo rm -f /etc/sudoers.d/90-google-ldap     # stale LDAP sudo grant
sudo apt-get purge -y sssd sssd-ldap sssd-tools libnss-sss libpam-sss
sudo rm -rf /etc/sssd /var/lib/sssd
```
