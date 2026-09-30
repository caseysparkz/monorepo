# caseysparkz.environment.dotfiles

Installs my config files.

## Role Variables

### `dotfiles_subdirectories`

A list of directories to create prior to symlinking config files.

```yaml
dotfiles_subdirectories:
  - path: "{{ ansible_facts.env.HOME }}/.config/SOMEDIRECTORY"
    mode: "0700"
```

### `dotfiles_symlinks`

A list of (config) files to link. `src` is relative to the role's `files/`
directory.

```yaml
dotfiles_symlinks:
  - src: "config/SOMEFILE.conf"
    dest: "{{ ansible_facts.env.HOME }}/.config/SOMEFILE.conf"
```

## Example Playbook

```yaml
---
- hosts: "localhost"
  roles:
     - role: "caseysparkz.environment.dotfiles"
```

## License

GPL-2.0-or-later
