# caseysparkz.security.ulimit

Hardens ulimits.

## Role Variables

### `ulimit_values`

```yaml
---
ulimit_values:
  - domain: "*"  # 0kb core filesize soft limit
    type: "soft"
    item: "core"
    value: "0"
  - domain: "*"  # 0kb core filesize hard limit
    type: "hard"
    item: "core"
    value: "0"
  - domain: "*"  # Max. 5 concurrent logins
    type: "hard"
    item: "maxlogins"
    value: "5"
```

## Example Playbook

```yaml
---
- hosts: "all"
  roles:
     - role: "caseysparkz.security.ulimit"
```

## License

GPL-2.0-or-later
