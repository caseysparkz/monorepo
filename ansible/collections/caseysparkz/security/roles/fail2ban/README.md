# caseysparkz.security.fail2ban

Install and configure Fail2Ban.

## Role Variables

### fail2ban_services

```yaml
fail2ban_services:
   - "sshd"
```

## Example Playbook

```yaml
---
- hosts: "servers"
  roles:
     - role: "caseysparkz.security.fail2ban"
```

## License

GPL-2.0-or-later
