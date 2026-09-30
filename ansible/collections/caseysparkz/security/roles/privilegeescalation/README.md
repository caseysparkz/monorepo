# caseysparkz.security.privilegeescalation

Mitigates common privilege escalation techniques.

## Role Variables

### `privilegeescalation_sudotimeout`

Set the `sudo` timeout (minutes). Defined in `vars/main.yml`, so it can only be
overridden with `--extra-vars`.

```yaml
---
privilegeescalation_sudotimeout: 0  # Always prompt for a password.
```

## Example Playbook

```yaml
---
- hosts: "all"
  roles:
     - role: "caseysparkz.security.privilegeescalation"
```

## License

GPL-2.0-or-later
