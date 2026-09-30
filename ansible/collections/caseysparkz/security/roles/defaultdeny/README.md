# caseysparkz.security.defaultdeny

Configures `iptables` with default deny.

**NB:** This role is not included in `caseysparkz.security.all`, and must be
run explicitly.

## Example Playbook

```yaml
---
- hosts: "localhost"
  roles:
     - role: "caseysparkz.security.defaultdeny"
```

## License

GPL-2.0-or-later
