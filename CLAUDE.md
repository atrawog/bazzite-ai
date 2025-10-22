# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is Bazzite AI - a custom fork of [Bazzite Developer Edition (DX)](https://github.com/ublue-os/bazzite-dx) with AI/ML-focused tooling and customizations. It's a container-based immutable Linux distribution built on top of [Bazzite](https://github.com/ublue-os/bazzite), extending it with developer tooling to match [Bluefin DX](https://docs.projectbluefin.io/bluefin-dx/) and [Aurora DX](https://docs.getaurora.dev/dx/aurora-dx-intro) functionality.

Key technologies:
- **Base**: ublue-os/bazzite-deck variants (KDE Plasma and GNOME, with/without NVIDIA)
- **Build System**: Containerfile-based OSTree image builds
- **Task Runner**: Just (justfile)
- **Package Manager**: dnf5, flatpak, homebrew (for fonts)
- **Container Tools**: Podman/Docker (preferred: Podman)
- **CI/CD**: GitHub Actions with buildah/cosign signing

## Architecture

### Container-Based OS Image

This is NOT a traditional application repository. It builds bootable container images using:

1. **Base Images**: Starts from `ghcr.io/ublue-os/bazzite-deck*:stable` variants
2. **Build Process**: Multi-stage Containerfile that:
   - Copies `system_files/` (runtime config) and `build_files/` (build scripts) into image
   - Runs `build_files/build.sh` which orchestrates numbered build scripts
   - Installs developer tools (VS Code, Docker, Android tools, BPF tools, etc.)
   - Configures system settings and services
3. **Output**: Signed container images pushed to GitHub Container Registry

### Build Script Execution Order

The `build_files/build.sh` orchestrator runs scripts in numerical order:
- `00-image-info.sh` - Sets image metadata
- `20-install-apps.sh` - Installs developer packages and repositories
- `40-services.sh` - Enables/disables systemd services
- `50-fix-opt.sh` - Fixes /opt directory permissions
- `60-clean-base.sh` - Removes gaming-specific configs (autologin, deck mode)
- `99-build-initramfs.sh` - Rebuilds initramfs
- `999-cleanup.sh` - Final cleanup

### System Files Structure

`system_files/` contains files copied to the OS image root:
- `etc/skel/` - Default user home directory skeleton (VS Code settings)
- `etc/ublue-os/system_flatpaks` - List of flatpak apps to install
- `usr/bin/` - Custom scripts (e.g., `gamemode-nested`)
- `usr/share/ublue-os/just/` - ujust recipes for end-user commands
- `usr/share/ublue-os/*-setup.hooks.d/` - Setup hooks for user/privileged initialization

## Common Development Commands

### Building Container Images

```bash
# Build the container image locally
just build [target_image] [tag]
# Examples:
just build bazzite-dx latest
just build  # Uses defaults from env vars

# The build uses environment variables:
# - IMAGE_NAME (default: bazzite-dx)
# - DEFAULT_TAG (default: latest)
# - REPO_ORGANIZATION (default: ublue-os)
```

### Building Virtual Machine Images

Uses bootc-image-builder (BIB) to create bootable VMs/ISOs from container images:

```bash
# Build QCOW2 VM image (requires sudo for rootful podman)
just build-qcow2 [target_image] [tag]
just rebuild-qcow2  # Rebuilds container first

# Build raw disk image
just build-raw [target_image] [tag]

# Build ISO installer
just build-iso [target_image] [tag]

# Aliases for QCOW2
just build-vm
just rebuild-vm
```

Output goes to `output/qcow2/`, `output/raw/`, or `output/bootiso/`.

### Running Virtual Machines

```bash
# Run VM in browser-based viewer (uses qemu-docker)
just run-vm-qcow2 [target_image] [tag]
just run-vm  # Alias for run-vm-qcow2
just run-vm-iso

# Will auto-build if image doesn't exist
# Opens web interface on http://localhost:8006+ (auto-increments port if busy)
# Default VM specs: 4 cores, 8GB RAM, 64GB disk, TPM, GPU passthrough
```

### Repository Maintenance

```bash
# Check justfile syntax
just check

# Auto-format all justfiles
just fix

# Clean build artifacts
just clean
just sudo-clean  # For rootful podman artifacts
```

## Image Variants

The CI builds 4 variants from different base images:
- `bazzite-ai` - KDE Plasma (from `bazzite-deck`)
- `bazzite-ai-gnome` - GNOME (from `bazzite-deck-gnome`)
- `bazzite-ai-nvidia` - KDE with NVIDIA drivers (from `bazzite-deck-nvidia`)
- `bazzite-ai-nvidia-gnome` - GNOME with NVIDIA (from `bazzite-deck-nvidia-gnome`)

## Key Modifications from Base Bazzite

Developer-focused changes made in `build_files/20-install-apps.sh`:

1. **Removed Gaming Defaults**:
   - Disabled autologin to Steam Game Mode
   - Removed SDDM steamos configs
   - Re-enabled login screens (GDM for GNOME, SDDM for KDE)
   - Re-enabled user switching and lock screen in KDE

2. **Added Developer Tools**:
   - VS Code (from Microsoft repo)
   - Docker CE + docker-compose
   - BPF tools (bpftrace, bpftop, bcc)
   - Container tools (podman-machine, podman-tui)
   - Android tools (android-tools, usbmuxd)
   - Cloud tools (restic, rclone)
   - Development utilities (ccache, flatpak-builder, qemu-kvm)
   - Python ramalama for LLM deployment

3. **Enabled Services**:
   - input-remapper (for device remapping)
   - uupd.timer (Universal Blue update manager)
   - ublue-setup-services (first-boot setup)

## Configuration Files

- `image.toml` - Minimal config for VM/raw images (20GB root partition)
- `iso.toml` - ISO installer config with kickstart to switch to registry image
- `image-versions.yaml` - Tracks base image versions/digests (managed by Renovate)
- `Containerfile` - Multi-stage build using BASE_IMAGE arg
- `artifacthub-repo.yml` - ArtifactHub metadata for image discovery

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/build.yml`):
1. Checks out code and sets up BTRFS storage
2. Fetches base image version from upstream Bazzite
3. Builds all 4 variants in parallel using buildah
4. Tags with multiple patterns (latest, stable, stable-{version}, {version}.{date})
5. Pushes to ghcr.io/atrawog/bazzite-ai*
6. Signs images with cosign (using SIGNING_SECRET)

## End-User Commands

Users of the built image can run these ujust commands (defined in `system_files/usr/share/ublue-os/just/95-bazzite-ai.just`):

```bash
# Install extra fonts via Homebrew
ujust install-fonts

# Toggle between Steam Game Mode and Desktop session on boot
ujust toggle-gamemode [gamemode|desktop|status|help]
```

## Important Notes

- **Immutable Base**: This builds an immutable OS. Changes go in `build_files/` scripts or `system_files/` configs.
- **Rootful Podman**: VM/ISO builds require rootful podman access (sudo).
- **Podman Preferred**: The justfile auto-detects podman or docker, preferring podman.
- **No Direct Installation**: Users rebase existing Bazzite installs using `rpm-ostree rebase`.
- **Derived from Bazzite Deck**: Uses `-deck` variants as base, then removes gaming-specific configs.
