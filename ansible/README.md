# Preferred Environment

**This README contains important information; please read it in its entirety
before running the playbook.**

These Ansible roles aim to harden Linux, improve system performance, and set up
my preferred user environment.

Its scripts, functions, aliases and packages are ones that I find useful and
enjoy having on any machine I regularly use.

While the repository is *intended* to be portable across Linux distributions,
this should not be assumed. The roles are written for, and tested on, Debian
(bookworm/trixie). The `packages` role also supports MacOS via Homebrew.

## Requirements

* `ansible-core` (installed via `pip install ./ansible`)
* `ansible-lint` (optional; installed via `pip install ./ansible[test]`)

## Usage

Install the collections, then run a playbook from this directory:

```sh
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/security.yml
```

Playbooks:

* `playbooks/localhost/environment.yml`
* `playbooks/performance.yml`
* `playbooks/security.yml`

## Collection Overview

This playbook consists of three collections:

* [caseysparkz.environment](./collections/caseysparkz/environment/README.md)
* [caseysparkz.performance](./collections/caseysparkz/performance/README.md)
* [caseysparkz.security](./collections/caseysparkz/security/README.md)

Further information on each collection's roles can be found in the corresponding
directory's README.

### Environment

The largest collection in this playbook, and the least relevant for people who
are not me.

This collection sets up my preferred user environments and configuration files
for Bash, Git, GnuPG, Gnu Screen, SSH, Vim, etc.

**NB:** If you intend to use this collection, first ensure that the git
submodules are initialized and up-to-date:

```sh
git submodule sync --init --recursive
```

Roles:

* [caseysparkz.environment.bash](./collections/caseysparkz/environment/roles/bash/README.md).
   Configures `bash` to my preference.
* [caseysparkz.environment.dotfiles](./collections/caseysparkz/environment/roles/dotfiles/README.md).
   Loads my dotfiles.
* [caseysparkz.environment.filesystem](./collections/caseysparkz/environment/roles/filesystem/README.md).
   Sets up my home directory.
* [caseysparkz.environment.git](./collections/caseysparkz/environment/roles/git/README.md).
   Configures `git` to my liking.
* [caseysparkz.environment.gnupg](./collections/caseysparkz/environment/roles/gnupg/README.md).
   Configures `gnupg`. Loads public keys, agent config, etc.
* [caseysparkz.environment.packages](./collections/caseysparkz/environment/roles/packages/README.md).
   Installs system packages I like to have.
* [caseysparkz.environment.screen](./collections/caseysparkz/environment/roles/screen/README.md).
   Configures Gnu `screen` to my preference.
* [caseysparkz.environment.scripts](./collections/caseysparkz/environment/roles/scripts/README.md).
   Installs personal scripts (`sh`/`python`).
* [caseysparkz.environment.ssh](./collections/caseysparkz/environment/roles/ssh/README.md).
   Sets up `~/.ssh/`.
* [caseysparkz.environment.vim](./collections/caseysparkz/environment/roles/vim/README.md).
   Configures `vim` to my preference.

### Security

This playbook makes **significant** changes to kernel, grub, sysctl, filesystem
modes, system services.
It also removes system crash reporters and enables unattended upgrades for
_`security` packages only_.

Read and understand the tasks before running. Similarly: don't hold a lit
firework in your hand, wait an hour after eating to go swimming, and wear your
sunscreen.

Roles:

* [caseysparkz.security.auditd](./collections/caseysparkz/security/roles/auditd/README.md)
* [caseysparkz.security.defaultdeny](./collections/caseysparkz/security/defaultdeny/README.md)
   (not included in `caseysparkz.security.all`)
* [caseysparkz.security.disablecrashreporters](./collections/caseysparkz/security/disablecrashreporters/README.md)
* [caseysparkz.security.fail2ban](./collections/caseysparkz/security/fail2ban/README.md)
* [caseysparkz.security.faillock](./collections/caseysparkz/security/faillock/README.md)
* [caseysparkz.security.kernel](./collections/caseysparkz/security/kernel/README.md)
* [caseysparkz.security.passwords](./collections/caseysparkz/security/passwords/README.md)
* [caseysparkz.security.privilegeescalation](./collections/caseysparkz/security/privilegeescalation/README.md)
* [caseysparkz.security.ssh](./collections/caseysparkz/security/ssh/README.md)
* [caseysparkz.security.ulimit](./collections/caseysparkz/security/ulimit/README.md)
* [caseysparkz.security.unattendedupgrades](./collections/caseysparkz/security/unattendedupgrades/README.md)

### Performance

Presently the smallest collection. Enables the fstrim timer, IO schedulers, and
zswap.

Roles:

* [caseysparkz.performance.filesystem](./collections/caseysparkz/performance/roles/filesystem/README.md)
* [caseysparkz.performance.ioscheduler](./collections/caseysparkz/performance/roles/ioscheduler/README.md)
* [caseysparkz.performance.zswap](./collections/caseysparkz/performance/roles/zswap/README.md)
