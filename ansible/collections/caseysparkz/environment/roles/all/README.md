# caseysparkz.environment.all

Runs all environment collection roles.

## Dependencies

* `caseysparkz.environment.bash`
* `caseysparkz.environment.dotfiles`
* `caseysparkz.environment.filesystem`
* `caseysparkz.environment.packages`
* `caseysparkz.environment.git`
* `caseysparkz.environment.gnupg`
* `caseysparkz.environment.screen`
* `caseysparkz.environment.scripts`
* `caseysparkz.environment.ssh`
* `caseysparkz.environment.vim`

## Example Playbook

```yaml
---
- hosts: "localhost"
  roles:
     - role: "caseysparkz.environment.all"
```

## License

GPL-2.0-or-later
