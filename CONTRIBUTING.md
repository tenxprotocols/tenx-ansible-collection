# TenX Ansible Collections - Development Guide

Internal development guide for the TenX Infrastructure Team.

## Quick Start

### Prerequisites

- Python 3.13+ (see [.tool-versions](.tool-versions))
- Ansible 2.9 or higher
- ansible-lint

### Creating New Collections

```bash
./.ansible-dev/scripts/new-collection.sh <collection-name> "<description>"
```

Example:
```bash
./.ansible-dev/scripts/new-collection.sh monitoring "Monitoring and alerting infrastructure"
```

Don't forget to add the new collection to the root [README.md](README.md).

### Creating New Roles

```bash
./.ansible-dev/scripts/new-role.sh <collection-name> <role-name> "<description>"
```

Example:
```bash
./.ansible-dev/scripts/new-role.sh monitoring prometheus "Installs and configures Prometheus"
```

Update the collection's README.md to document the new role.

## Standards

### YAML Style

- 2 spaces for indentation
- Use `---` at the start of files
- Quote strings when necessary
- Variables: `<role_name>_variable_name`

### Task Naming

Be descriptive and action-oriented:
- Good: `Install Docker packages`, `Configure containerd daemon`
- Bad: `Docker`, `Setup`, `Task 1`

### Module Usage

- Always use FQCN: `ansible.builtin.apt` not `apt`
- Use `ansible.builtin.systemd` for systemd systems

### Supported Platforms

- Ubuntu: 20.04, 22.04, 24.04
- Debian: 12 (bookworm)

## Validation

Before committing:

```bash
# Validate structure
./.ansible-dev/scripts/validate-structure.sh

# Lint your changes
ansible-lint <collection-name>/
```

## Commit Messages

Use conventional format:

```
<type>(<scope>): <subject>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`

Examples:
- `feat(tezos): add baker role`
- `fix(kubernetes): correct CIDR validation`
- `docs(install): update docker role README`

## License

All code is proprietary. See [LICENSE](LICENSE).
