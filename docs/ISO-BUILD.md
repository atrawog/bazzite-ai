# Building Bazzite AI ISO Images

This guide explains how to build bootable ISO installer images for Bazzite AI.

## Prerequisites

### System Requirements
- **Operating System:** Fedora Linux (or compatible)
- **Virtualization:** KVM support (`/dev/kvm` must exist)
- **Privileges:** Root/sudo access (for rootful podman)
- **Disk Space:** ~20-30GB free (10-15GB per ISO)
- **RAM:** 8GB+ recommended
- **Time:** 30-60 minutes per ISO

### Required Software
```bash
sudo dnf install podman just qemu-kvm
```

### Verify KVM Support
```bash
ls -l /dev/kvm
# Should show: crw-rw-rw-+ 1 root kvm ...
```

## Building ISOs

### Build Unified ISO (All Hardware)
```bash
# Build from local container image
just build-iso

# Or rebuild container first, then build ISO
just rebuild-iso
```

Output: `output/bootiso/install.iso`

The unified ISO works on all hardware (AMD/Intel/NVIDIA) using the bazzite-nvidia-open base.

## Workflow for Release

### 1. Build Container Image
```bash
# Built automatically by GitHub Actions
# Or build locally:
just build bazzite-ai latest
```

### 2. Build ISO from Container Image
```bash
# Pull published image from GHCR
podman pull ghcr.io/atrawog/bazzite-ai:latest

# Tag for local use
podman tag ghcr.io/atrawog/bazzite-ai:latest localhost/bazzite-ai:latest

# Build ISO
just build-iso localhost/bazzite-ai latest
mv output/bootiso/install.iso bazzite-ai-$(date +%Y%m%d).iso
```

### 3. Generate Checksums
```bash
# Create SHA256 checksums
sha256sum bazzite-ai-*.iso > SHA256SUMS

# Verify checksums
sha256sum -c SHA256SUMS
```

### 4. Test ISO (Optional)
```bash
# Test ISO in VM
just run-vm-iso
```

Opens browser-based VM interface on http://localhost:8006+

### 5. Create GitHub Release
```bash
# Get the current stable tag from container images
TAG="42.$(date +%Y%m%d)"

# Create release
gh release create "$TAG" \
  --title "Bazzite AI $TAG" \
  --notes "Bazzite AI release $TAG

## Container Image
- \`ghcr.io/atrawog/bazzite-ai:$TAG\`

Unified image based on bazzite-nvidia-open (works on all hardware: AMD/Intel/NVIDIA).

## ISO Download
See assets below.

## Installation
Download the unified ISO (works on all hardware):
- **bazzite-ai-*.iso** - KDE Plasma (AMD/Intel/NVIDIA)

Create a bootable USB drive and follow the installation prompts.

## For Existing Users
Rebase to this version:
\`\`\`bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/atrawog/bazzite-ai:$TAG
\`\`\`
" \
  bazzite-ai-*.iso \
  SHA256SUMS
```

## Understanding the Build Process

### What bootc-image-builder Does
1. Pulls the container image specified in `iso.toml`
2. Extracts the OSTree commit from the container
3. Creates an Anaconda installer ISO
4. Configures kickstart to switch to the registry image on first boot
5. Outputs to `output/bootiso/install.iso`

### Configuration Files
- **iso.toml** - Config for unified bazzite-ai ISO
  - Points to `ghcr.io/atrawog/bazzite-ai:latest`
- **image.toml** - Config for raw/qcow2 disk images (not ISOs)

### Build Artifacts
```
output/
└── bootiso/
    ├── install.iso          # The bootable ISO
    ├── manifest.json        # Build manifest
    └── bootc-manifest.json  # Bootc manifest
```

## Troubleshooting

### "Error: /dev/kvm: Permission denied"
```bash
# Check KVM permissions
ls -l /dev/kvm

# Add your user to kvm group
sudo usermod -aG kvm $USER

# Log out and back in, or:
newgrp kvm
```

### "Error: rootful podman required"
The ISO builder requires rootful podman. The Justfile automatically uses sudo.

### "Error: insufficient disk space"
Each ISO build requires ~10-15GB temporary space:
```bash
# Check available space
df -h /var/lib/containers

# Clean up old builds
just sudo-clean
```

### Build Takes Too Long
Normal build times:
- First build: 45-60 minutes (downloads all packages)
- Subsequent builds: 20-30 minutes (uses cached packages)

Speed up:
- Use SSD storage
- Increase RAM allocation
- Close resource-heavy applications

## Advanced Usage

### Build from Specific Tag
```bash
just build-iso localhost/bazzite-ai 42.20251022
```

### Build with Custom Config
```bash
# Modify iso.toml, then:
just build-iso
```

### Build Without Pulling Latest
```bash
# Use locally cached images:
just build-iso localhost/bazzite-ai latest
```

## Release Checklist

- [ ] Container images built and pushed to GHCR
- [ ] Container images signed with cosign
- [ ] Both ISOs built successfully
- [ ] ISOs tested in VMs
- [ ] SHA256SUMS created and verified
- [ ] GitHub release created with proper tag
- [ ] Release notes include installation instructions
- [ ] ISOs and checksums uploaded to release
- [ ] README.md updated with latest release link

## Additional Resources

- [bootc Documentation](https://containers.github.io/bootc/)
- [bootc-image-builder](https://github.com/osbuild/bootc-image-builder)
- [Bazzite Documentation](https://docs.bazzite.gg/)
- [Creating Bootable USB Drives](https://fedoraproject.org/wiki/How_to_create_and_use_Live_USB)
