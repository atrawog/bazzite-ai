# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is Bazzite AI - a custom fork of [Bazzite Developer Edition (DX)](https://github.com/ublue-os/bazzite-dx) with AI/ML-focused tooling and customizations. It's a container-based immutable Linux distribution built on top of [Bazzite](https://github.com/ublue-os/bazzite), extending it with developer tooling.

**⚠️ Important**: Bazzite AI **only supports KDE Plasma variants**. GNOME variants are not officially supported.

Key technologies:
- **Base**: ublue-os/bazzite-deck (KDE Plasma) with/without NVIDIA
- **Desktop**: KDE Plasma only
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

# Clean release artifacts (ISOs, torrents, releases/ directory)
just release-clean
```

**Note:** The `releases/` directory containing ISO images and torrents is git-ignored.

## Release Management and ISO Distribution

This project includes a comprehensive workflow for building ISO installers and distributing them via BitTorrent (due to GitHub's 2GB file size limit).

### Release Directory Structure

```
releases/
├── 42.20251022/              # Version-specific directory
│   ├── bazzite-ai-42.20251022.iso
│   ├── bazzite-ai-nvidia-42.20251022.iso
│   ├── bazzite-ai-42.20251022.iso.torrent
│   ├── bazzite-ai-nvidia-42.20251022.iso.torrent
│   ├── SHA256SUMS
│   └── 42.20251022-magnets.txt
└── latest -> 42.20251022     # Symlink to current release
```

### Complete Release Workflow

The `just release` command automates the entire release process:

```bash
# Full automated release (7 steps)
just release [tag]

# Steps performed:
# 1. Pull container images from GHCR
# 2. Build both ISO variants (30-60 min each)
# 3. Generate SHA256 checksums
# 4. Organize files into releases/{tag}/ directory
# 5. Create .torrent files with public trackers
# 6. Start seeding service (if configured)
# 7. Create GitHub release with torrents
```

### Individual Release Commands

**ISO Building:**
```bash
# Pull container images from registry
just release-pull [tag]

# Build both ISO variants
just release-build-isos [tag]

# Generate and verify checksums
just release-checksums
```

**File Organization:**
```bash
# Organize release files into releases/{tag}/ structure
just release-organize [tag]

# Creates:
# - releases/{tag}/ directory
# - Moves ISOs, torrents, checksums into it
# - Updates releases/latest symlink
```

**Torrent Distribution:**
```bash
# Create .torrent files with public trackers
just release-create-torrents [tag]

# Display torrent info and magnet links
just release-torrents-info [tag]
```

**Seeding Management:**
```bash
# Set up transmission-daemon systemd service
just release-setup-seeding

# Start seeding torrents (adds to transmission-daemon)
just release-seed-start [tag]

# Stop seeding service
just release-seed-stop

# Show seeding status and statistics
just release-seed-status
```

The seeding service:
- Runs as a systemd user service (`bazzite-ai-seeding.service`)
- Uses transmission-daemon for BitTorrent
- Configured with 2.0 ratio limit (seeds to 200% uploaded)
- Continues seeding across reboots
- Configuration: `.transmission-daemon.json` (git-ignored)

**GitHub Release:**
```bash
# Create GitHub release with torrent files
just release-create [tag]

# Uploads:
# - .torrent files (small enough for GitHub)
# - SHA256SUMS
# - Magnet links in release notes
# - Instructions for downloading via BitTorrent
```

**Utilities:**
```bash
# List all releases
just release-list

# Clean release artifacts (prompts for confirmation)
just release-clean

# Verify checksums
just release-verify

# Upload files to existing release
just release-upload [tag] [files...]
```

### Why BitTorrent Distribution?

ISOs are 8+ GB each, exceeding GitHub's 2GB release asset limit. BitTorrent provides:
- **Scalability**: Distributed bandwidth from seeders
- **Reliability**: Resume interrupted downloads
- **Verification**: Built-in integrity checking
- **Cost**: No hosting fees or bandwidth limits

Users can download via:
1. `.torrent` files from GitHub releases
2. Magnet links (in release notes)
3. Any BitTorrent client (Transmission, qBittorrent, Deluge)

## Image Variants

Bazzite AI builds **2 KDE Plasma variants** (GNOME is not supported):

- **bazzite-ai** - KDE Plasma (from `bazzite-deck`)
- **bazzite-ai-nvidia** - KDE Plasma with NVIDIA drivers (from `bazzite-deck-nvidia`)

⚠️ **Note**: Only KDE variants are officially supported. Any GNOME builds in CI are experimental/unofficial.

## Devcontainer Variant

**bazzite-ai-devcontainer** - Development container with optional CUDA support

### Purpose
- Safe isolated environment for Claude Code with `--dangerously-skip-permissions`
- Optional CUDA-accelerated AI/ML workflows (on NVIDIA systems)
- Consistent development environment across GPU and non-GPU systems
- No systemd overhead - pure tooling

### Key Features
- **Unified Configuration**: One config works on both GPU and non-GPU systems
- **Auto-Detection**: GPU automatically detected and enabled when available
- **Pre-built Images**: Always uses latest from GitHub Container Registry
- **Base**: Fedora 42 with all tools from bazzite-ai-nvidia (KDE)
- **VS Code**: Native Dev Containers support

### Host Requirements

**For GPU acceleration** (optional):
1. Must use **bazzite-ai-nvidia** (KDE variant only)
2. nvidia-container-toolkit (pre-installed)
3. CDI config via `ujust setup-gpu-containers`

**For CPU-only**: Works on any bazzite-ai variant.

See `docs/HOST-SETUP-GPU.md` and `docs/DEVCONTAINER.md`.

### Justfile Commands

```bash
just pull-devcontainer [tag]    # Pull from GHCR
just build-devcontainer [tag]   # Build locally
just run-devcontainer [tag]     # Run with GPU
just test-cuda-devcontainer     # Test CUDA
just run-devcontainer-no-gpu    # CPU only
```

### VS Code Usage

1. Install Dev Containers extension
2. Open repo in VS Code
3. Command Palette → "Reopen in Container"
4. GPU auto-detected (works on both GPU and non-GPU systems)

The unified configuration pulls the latest image from GHCR automatically. To update, rebuild the container.

See `docs/DEVCONTAINER.md`.

### ujust Commands

On bazzite-ai-nvidia (KDE):

```bash
ujust setup-gpu-containers  # One-time GPU setup
```

## Key Modifications from Base Bazzite

Developer-focused changes for **KDE Plasma variants** in `build_files/20-install-apps.sh`:

1. **Removed Gaming Defaults**:
   - Disabled autologin to Steam Game Mode
   - Removed SDDM steamos configs
   - Re-enabled SDDM login screens (KDE)
   - Re-enabled user switching and lock screen in KDE

2. **Added Developer Tools**:
   - VS Code (from Microsoft repo)
   - Docker CE + docker-compose
   - BPF tools (bpftrace, bpftop, bcc)
   - Container tools (podman-machine, podman-tui)
   - **nvidia-container-toolkit** (nvidia variant only)
   - Android tools (android-tools, usbmuxd)
   - Cloud tools (restic, rclone)
   - Development utilities (ccache, flatpak-builder, qemu-kvm)
   - Python ramalama for LLM deployment

3. **Enabled Services**:
   - input-remapper (for device remapping)
   - uupd.timer (Universal Blue update manager)
   - ublue-setup-services (first-boot setup)

## Configuration Files

**Container Build:**
- `Containerfile` - Multi-stage build using BASE_IMAGE arg
- `image-versions.yaml` - Tracks base image versions/digests (managed by Renovate)
- `artifacthub-repo.yml` - ArtifactHub metadata for image discovery

**External Repositories:**
- `vscode` - Microsoft repository for VS Code
- `docker-ce-stable` - Docker CE repository
- `microsoft-prod` - Microsoft .NET SDK repository
- `copr:kylegospo:coolercontrol` - CoolerControl COPR (hardware monitoring for AIOs/fan hubs)
- `copr:pgdev:ghostty` - Ghostty terminal COPR
- All external repos disabled by default, enabled only during installation

**ISO/VM Images:**
- `image.toml` - Minimal config for VM/raw images (20GB root partition)
- `iso.toml` - Base ISO installer config with kickstart to switch to registry image
- `iso-nvidia.toml` - NVIDIA ISO installer config

**Release Infrastructure:**
- `releases/` - Directory structure for organized release artifacts (git-ignored)
- `.transmission-daemon.json` - Torrent seeding daemon config (git-ignored)
- `scripts/setup-seeding-service.sh` - Sets up systemd seeding service
- `scripts/create-release.sh` - Automated release creation script

**Devcontainer:**
- `Containerfile.devcontainer` - Devcontainer build (Fedora 42 + dev tools)
- `.devcontainer/devcontainer.json` - Unified VS Code configuration (GPU auto-detection)
- `build_files/devcontainer/install-devcontainer-tools.sh` - Tool installation
- `docs/DEVCONTAINER.md` - Usage guide
- `docs/HOST-SETUP-GPU.md` - GPU setup (nvidia variant)

**Documentation:**
- `docs/ISO-BUILD.md` - Comprehensive ISO building guide
- `CLAUDE.md` - This file, guidance for Claude Code

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/build.yml`):
1. Checks out code and sets up BTRFS storage
2. Fetches base image version from upstream Bazzite
3. Builds KDE variants in parallel using buildah (bazzite-ai, bazzite-ai-nvidia)
4. Builds bazzite-ai-devcontainer (CUDA-enabled development container)
5. Tags with multiple patterns (latest, stable, stable-{version}, {version}.{date})
6. Pushes to ghcr.io/atrawog/bazzite-ai* and ghcr.io/atrawog/bazzite-ai-devcontainer
7. Signs images with cosign (using SIGNING_SECRET)

## End-User Commands

Users of the built image can run these ujust commands (defined in `system_files/usr/share/ublue-os/just/95-bazzite-ai.just`):

```bash
# Install extra fonts via Homebrew
ujust install-fonts

# Toggle between Steam Game Mode and Desktop session on boot (KDE only)
ujust toggle-gamemode [gamemode|desktop|status|help]

# Setup GPU access for containers (bazzite-ai-nvidia KDE only)
ujust setup-gpu-containers
```

## Important Notes

- **KDE Only**: Bazzite AI only supports KDE Plasma variants, not GNOME.
- **NVIDIA Variant**: GPU container support requires bazzite-ai-nvidia (KDE).
- **Immutable Base**: This builds an immutable OS. Changes go in `build_files/` scripts or `system_files/` configs.
- **Rootful Podman**: VM/ISO builds require rootful podman access (sudo).
- **Podman Preferred**: The justfile auto-detects podman or docker, preferring podman.
- **No Direct Installation**: Users rebase existing Bazzite installs using `rpm-ostree rebase`.
- **Derived from Bazzite Deck**: Uses `-deck` variants as base, then removes gaming-specific configs.
- **Release Directory**: `releases/` contains version-specific subdirectories with ISOs, torrents, and checksums. This directory is git-ignored.
- **BitTorrent Distribution**: ISOs exceed GitHub's 2GB limit, so they're distributed via BitTorrent. The seeding service uses transmission-daemon as a systemd user service.
- **ISO Build Time**: Each ISO variant takes 30-60 minutes to build. The complete release workflow takes 1-2 hours.
