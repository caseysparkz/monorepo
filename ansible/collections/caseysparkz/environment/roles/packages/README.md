# caseysparkz.environment.packages

Installs my preferred packages.

## Role Variables

### `packages_apt`

Packages to install with `apt` on Debian-family hosts.

```yaml
---
packages_apt:
  - "dirmngr"
  - "dnsutils"
  - "docker-ce"
  - "fwupd"
  - "gnupg2"
  - "nmap"
  - "wget"
```

### `packages_homebrew`

Packages to install with Homebrew on MacOS hosts. Homebrew is installed first
if `/opt/homebrew/` does not exist.

```yaml
---
packages_homebrew:
  - "gh"
  - "git"
  - "gnupg"
  - "hashicorp/tap/terraform"
  - "shellcheck"
  - "trivy"
  - "wget"
```

See `defaults/main.yml` for the full lists.

## Example Playbook

```yaml
---
- hosts: "localhost"
  roles:
     - role: "caseysparkz.environment.packages"
```

## License

GPL-2.0-or-later
