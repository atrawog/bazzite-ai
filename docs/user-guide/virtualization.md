# Virtualization Guide

Bazzite AI includes comprehensive virtualization support out-of-the-box.

## What's Pre-Configured

✅ **libvirtd service** - Enabled at boot, manages virtual machines
✅ **virt-manager GUI** - Pre-installed for easy VM management
✅ **libvirt group** - Users added automatically (sudo-free VM management)
✅ **KVM kernel args** - Added on first boot for optimal VM compatibility
✅ **QEMU/KVM** - Full hardware virtualization support

## Quick Start

1. **First Boot**: System adds KVM kernel args automatically
2. **Reboot**: Kernel args take effect (one-time only)
3. **Open virt-manager**: Pre-installed, available in application menu
4. **Create VM**: Click "+" button, follow wizard
5. **No sudo needed**: You're already in the libvirt group

## Managing Libvirtd Service

```bash
# Check virtualization status
ujust toggle-libvirtd status

# Disable libvirtd (if not using VMs)
ujust toggle-libvirtd disable

# Re-enable libvirtd
ujust toggle-libvirtd enable
```

## What Are KVM Kernel Args?

KVM kernel arguments improve VM compatibility:
- `kvm.ignore_msrs=1` - Allows VMs to ignore unsupported CPU registers
- `kvm.report_ignored_msrs=0` - Reduces kernel log spam

These are safe for all systems and improve VM stability.

## Advanced Virtualization

For GPU passthrough, Looking Glass, or VFIO:

```bash
ujust setup-virtualization help
```

This provides access to:
- VFIO GPU passthrough
- Looking Glass low-latency display
- USB hot plugging
- IOMMU configuration

:::{note}
Advanced features require specific hardware and manual configuration.
:::

## Troubleshooting

### VM creation fails

```bash
ujust toggle-libvirtd status  # Check service status
```

### Permission denied

- Logout/login to apply group membership
- Or reboot system

### KVM not available

- Check CPU virtualization enabled in BIOS (Intel VT-x / AMD-V)
- Verify: `lsmod | grep kvm`

## System Requirements

### CPU Virtualization

Your CPU must support hardware virtualization:
- **Intel**: VT-x (Intel Virtualization Technology)
- **AMD**: AMD-V (AMD Virtualization)

Enable in BIOS/UEFI settings before creating VMs.

### Checking Support

```bash
# Check if CPU supports virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo
# Non-zero result = supported

# Check if KVM module is loaded
lsmod | grep kvm
# Should show kvm_intel or kvm_amd

# Check libvirtd status
ujust toggle-libvirtd status
```

## Creating Your First VM

1. **Open virt-manager** from application menu
2. **File → New Virtual Machine**
3. **Choose installation method**:
   - Local install media (ISO)
   - Network install (URL)
   - Import existing disk image
4. **Select ISO or network source**
5. **Configure memory and CPUs**:
   - Recommended: 2GB RAM minimum, 2 CPUs
6. **Create virtual disk**:
   - Recommended: 20GB minimum for most OSes
7. **Review and finish**
8. **VM starts automatically**

## Common VM Operations

### Starting/Stopping VMs

```bash
# Via virt-manager GUI
# Right-click VM → Run/Shutdown/Reboot

# Via virsh command line
virsh list --all           # List all VMs
virsh start vm-name        # Start VM
virsh shutdown vm-name     # Graceful shutdown
virsh destroy vm-name      # Force stop
```

### VM Storage Locations

Default VM storage locations:
- **Images**: `/var/lib/libvirt/images/`
- **ISOs**: `$HOME/` or `/var/lib/libvirt/images/`

### Snapshots

Create snapshots for easy rollback:
1. Select VM in virt-manager
2. **VM → Snapshots**
3. **Create new snapshot**

## Performance Tips

### CPU Pinning

For better performance, consider CPU pinning in VM configuration:
- Edit VM → CPUs → Topology
- Match host CPU topology

### Virtio Drivers

Use virtio drivers for best performance:
- **Network**: virtio-net
- **Storage**: virtio-blk or virtio-scsi
- **Graphics**: virtio-gpu (for Linux guests)

### Memory Ballooning

Enable memory ballooning for dynamic memory allocation:
- VM Settings → Memory
- Enable "Current allocation"

## Security Considerations

### Network Isolation

VMs use NAT by default for network access:
- Isolated from host network
- Internet access via host
- VMs can communicate with each other

### Host-Only Networks

For VM-to-host only communication:
1. virt-manager → Edit → Connection Details
2. Virtual Networks → Add
3. Configure isolated network

## Integration with Other Tools

### Docker/Podman

VMs and containers work together:
- Run containers inside VMs
- Use VMs for isolated container workloads
- Test multi-node setups

### Apptainer

Apptainer provides HPC-style containers:
```bash
ujust apptainer-info  # Learn about Apptainer integration
```

## Additional Resources

- [Libvirt Documentation](https://libvirt.org/docs.html)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [KVM Documentation](https://www.linux-kvm.org/page/Documents)
- [Bazzite Setup Virtualization](https://docs.bazzite.gg/Advanced/Virtualization/) (upstream guide)

## See Also

- {doc}`containers/index` - Container development workflows
- {doc}`winboat` - Windows app integration
