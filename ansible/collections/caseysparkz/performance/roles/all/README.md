# caseysparkz.performance.all

Runs all performance roles.

## Dependencies

* `caseysparkz.performance.filesystem`
* `caseysparkz.performance.ioscheduler`
* `caseysparkz.performance.zswap`

## Example Playbook

```yaml
---
- hosts: "all"
  roles:
     - role: "caseysparkz.performance.all"
```

## License

GPL-2.0-or-later
