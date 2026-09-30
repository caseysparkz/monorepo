# caseysparkz.security.kernel

Hardens the Linux kernel.

## Role Variables

### `kernel_grubflags`

Kernel command-line flags added to GRUB.

```yaml
---
kernel_grubflags:
  - option: "rhgb"
    value: "slab_nomerge quiet"
  - option: "amd_iommu"
    value: "on"
  - option: "debugfs"
    value: "off"
  - option: "init_on_alloc"
    value: 1
  - option: "init_on_free"
    value: 1
  # ...
```

### `kernel_sysctlvars`

Sysctl values to set.

```yaml
---
kernel_sysctlvars:
  - name: "net.ipv6.conf.default.use_tempaddr"
    value: 2
  - name: "net.unix.max_dgram_qlen"
    value: 50
  - name: "vm.mmap_min_addr"
    value: 4096
  - name: "vm.mmap_rnd_bits"
    value: 32
  - name: "vm.mmap_rnd_compat_bits"
    value: 16
  - name: "vm.overcommit_memory"
    value: 0
  - name: "vm.overcommit_ratio"
    value: 50
  - name: "vm.unprivileged_userfaultfd"
    value: 0
  # ...
```

See `defaults/main.yml` for the full lists.

## Example Playbook

```yaml
---
- hosts: "all"
  roles:
     - role: "caseysparkz.security.kernel"
```

## License

GPL-2.0-or-later
