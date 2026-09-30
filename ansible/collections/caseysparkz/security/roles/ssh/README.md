# caseysparkz.security.ssh

Hardens `ssh`/`sshd`.

## Role Variables

### `ssh_config`

A list of `regexp`/`line` pairs applied to `sshd_config`.

**NB:** The defaults restrict SSH logins to members of the `sshusers` group.

```yaml
---
ssh_config:
  - regexp: "(?i)^\\s*^AllowAgentForwarding"  # Turn off agent forwarding
    line: "AllowAgentForwarding no"
  - regexp: "(?i)^\\s*^AllowGroups"  # Limit ssh users to sshusers group
    line: "AllowGroups sshusers"
  - regexp: "(?i)^\\s*^HostbasedAuthentication"  # Disable host-based auth
    line: "HostbasedAuthentication no"
  - regexp: "(?i)^\\s*^ListenAddress"  # Listen on all ifaces
    line: "ListenAddress 0.0.0.0"
  - regexp: "(?i)^\\s*^PasswordAuthentication"  # Disable password auth
    line: "PasswordAuthentication no"
  - regexp: "(?i)^\\s*^PermitRootLogin"  # Disable root login
    line: "PermitRootLogin no"
  - regexp: "(?i)^\\s*^Port"  # Set SSH port
    line: "Port 22"
  - regexp: "(?i)^\\s*^X11Forwarding"  # Disable X11 forwarding
    line: "X11Forwarding no"
  # ...
```

See `defaults/main.yml` for the full list, including the post-quantum
`KexAlgorithms`.

## Example Playbook

```yaml
---
- hosts: "servers"
  roles:
     - role: "caseysparkz.security.ssh"
```

## License

GPL-2.0-or-later
