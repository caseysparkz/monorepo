---
title: 'Bootstrapping a Daily Driver Linux Environment with Ansible'
date: '2023-10-03'
draft: false
language: 'en'
summary: 'Leveraging Ansible to build secure end-user Linux systems and support my distro-hopping habit.'
featured_image: '../assets/images/posts/code/bootstrapping_a_daily_driver_linux_environment_with_ansible.png'
categories: 'code'
tags:
    - 'curations'
    - 'code'

---
[Github Repository](https://github.com/caseysparkz/env)

The playbook aims to:

* Harden Linux.
* Optimize system performance.
* Installing some useful packages.
* Set up an environment that I like.

To achieve this, the playbook consists of four roles. Respectively:

* `security`
* `performance_tweaks`
* `environment`

---
## Playbook Roles

### Security
This playbook makes **significant** changes to kernel, grub, sysctl, filesystem
modes, system services, based on the [Center for Internet Security's Linux
Benchmarks](https://www.cisecurity.org/benchmark). Not all benchmarks are
implemented, though parity remains the end-goal.

The playbook also disables system crash reporters and enables unattended
upgrades for _security packages only_.

### Performance Tweaks

Presently the smallest role. Enables the fstrim timer, IO schedulers, some other
stuff. RTFM.

### Environment

The largest role in this playbook, and the least relevant for people who are not
me. This role sets up my preferred user environments and dotfiles for Bash, Git,
GnuPG, Gnu Screen, SSH, Vim, etc.

It modifies the `${PATH}` environment variable to include my personal scripts
directories and removes Snap (on Ubuntu systems).
