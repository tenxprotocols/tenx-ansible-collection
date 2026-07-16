# {{ROLE_NAME}} Role

Brief description of what this role does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Requirements

- Ansible >= 2.9
- Target system with internet access (if applicable)
- Supported operating systems:
  - Ubuntu: 20.04, 22.04, 24.04
  - Debian: bookworm
  - Other supported OS

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Variable description
{{ROLE_NAME}}_variable: "default_value"

# Another variable description
{{ROLE_NAME}}_enabled: true
```

## Dependencies

None.

## Example Playbooks

Basic usage:
```yaml
- hosts: servers
  roles:
    - role: tenx.{{COLLECTION_NAME}}.{{ROLE_NAME}}
```

With custom variables:
```yaml
- hosts: servers
  roles:
    - role: tenx.{{COLLECTION_NAME}}.{{ROLE_NAME}}
      vars:
        {{ROLE_NAME}}_variable: "custom_value"
        {{ROLE_NAME}}_enabled: false
```

## Testing

Describe how to test this role if applicable.

## License

UNLICENSED - All Rights Reserved

## Author Information

TenX Protocols Infrastructure Team
