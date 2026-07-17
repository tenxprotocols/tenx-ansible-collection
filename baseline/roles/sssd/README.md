# tenx.baseline.sssd

Configures SSSD against [Google Secure LDAP](https://support.google.com/a/answer/9048516)
so Google Workspace (`@tenx.inc`) accounts exist as POSIX users on the host —
UID/GID, groups, home directory and shell all come from Google Directory.

## How login works

- **NetBird native SSH (recommended):** NetBird ≥ 0.61 runs an identity-aware
  SSH server (`netbird up --allow-server-ssh`). You authenticate with your
  Google account via OIDC/JWT and the NetBird access policy maps your user or
  group to local OS users. NetBird resolves those users through `getent`
  (NSS), which is exactly what SSSD provides — no passwords, no keys on disk.
- **Plain OpenSSH (optional):** with `sssd_enable_ssh_password_auth: true`,
  PAM/SSSD verifies your Google password against LDAP. Off by default.
  The role always writes `/etc/ssh/sshd_config.d/60-google-ldap.conf` with
  the resulting `PasswordAuthentication` policy (`no` unless opted in) —
  with `pam_sss` installed, an open password prompt would let internet
  scanners verify password guesses against Google Directory, and Secure
  LDAP binds bypass 2-Step Verification. Do not leave password auth on for
  internet-exposed hosts.

Usernames are the local part of the email: `geoff@tenx.inc` → `geoff`.

## One-time Google Admin Console setup

1. [admin.google.com](https://admin.google.com) → **Apps → LDAP → Add Client**.
2. Name it (e.g. `tenx-infra-ssh`), set access permissions:
   - *Verify user credentials*: entire domain (or an OU/group)
   - *Read user information*: entire domain
   - *Read group information*: **On**
3. Download the generated certificate zip (contains `.crt` and `.key`).
4. Set the client status to **On** (it defaults to off!).
5. Base64-encode both files for Semaphore:

   ```bash
   base64 -i Google_*.crt | tr -d '\n'   # -> GOOGLE_LDAP_CLIENT_CERT_B64
   base64 -i Google_*.key | tr -d '\n'   # -> GOOGLE_LDAP_CLIENT_KEY_B64
   ```

6. Add both as **secret** variables in the Semaphore Environment used by the
   baseline task template.

No LDAP bind username/password is needed — Google authenticates the client
by its TLS certificate.

## Variables

| Variable | Default | Description |
|---|---|---|
| `sssd_google_domain` | `tenx.inc` | Workspace domain / SSSD domain name |
| `sssd_ldap_uri` | `ldaps://ldap.google.com:636` | Secure LDAP endpoint |
| `sssd_ldap_search_base` | derived (`dc=tenx,dc=inc`) | LDAP search base |
| `sssd_ldap_client_cert_b64` | env `GOOGLE_LDAP_CLIENT_CERT_B64` | base64 PEM client certificate |
| `sssd_ldap_client_key_b64` | env `GOOGLE_LDAP_CLIENT_KEY_B64` | base64 PEM client key |
| `sssd_default_shell` | `/bin/bash` | shell for LDAP users |
| `sssd_override_homedir` | `/home/%u` | home directory pattern |
| `sssd_manage_mkhomedir` | `true` | create home dirs on first login |
| `sssd_precreate_home_groups` | `sssd_sudo_groups` | LDAP groups whose members get home dirs pre-created (NetBird SSH chdirs into the home before PAM can create it, so first NetBird logins fail without this) |
| `sssd_sudo_groups` | `[infra-admins]` | Google groups granted NOPASSWD sudo |
| `sssd_enable_ssh_password_auth` | `false` | allow Google-password SSH logins |

If the certificate variables are empty the role logs a warning and skips —
the baseline stays deployable before the LDAP client exists.

## NetBird dashboard setup (once per network)

1. Enable the SSH server on the peers (`netbird up --allow-server-ssh`).
2. In the access control policy allowing port 22 to these peers, configure
   the SSH user mapping: source group (e.g. `infra-admins`) → allowed local
   OS users (e.g. "same as NetBird username" or an explicit list).

## Verification

```bash
getent passwd geoff            # user resolves via SSSD
id geoff                       # groups include infra-admins
netbird ssh <peer>             # login via Google OIDC
sudo -l                        # sudo granted via /etc/sudoers.d/90-google-ldap
```
