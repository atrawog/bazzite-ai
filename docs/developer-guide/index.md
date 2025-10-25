---
title: Developer Guide
---

# Developer Guide

Welcome to the Bazzite AI developer guide! This section covers building images, managing releases, testing, and contributing to the project.

## Topics Covered

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🔨 Building Images
:link: building/index
:link-type: doc

Learn how to build container images, ISOs, and VM images.
:::

:::{grid-item-card} 🧪 Testing
:link: testing/index
:link-type: doc

Comprehensive testing guides for containers, flatpaks, and system components.
:::

::::

## Quick Start

### Building Container Images

```bash
# Build the OS container image
just build

# Build development containers
just build-container         # CPU-only
just build-container-nvidia  # GPU variant
```

### Building Bootable Images

```bash
# Build ISO installer
just build-iso

# Build VM image (QCOW2)
just build-qcow2

# Run VM for testing
just run-vm
```

### Creating Releases

```bash
# Complete release workflow
just release

# Individual steps
just release-build-isos
just release-create-torrents
just release-seed-start
just release-create
```

## Development Workflow

::::{grid} 1 1 2 3
:gutter: 2

:::{grid-item-card} 1. Make Changes
Edit files in `build_files/` or `system_files/`
:::

:::{grid-item-card} 2. Build & Test
```bash
just build
just build-vm
just run-vm
```
:::

:::{grid-item-card} 3. Commit
```bash
git add .
git commit -m "Add: feature"
```
:::

:::{grid-item-card} 4. Push
```bash
git push
```
:::

:::{grid-item-card} 5. CI/CD
GitHub Actions builds and pushes images
:::

:::{grid-item-card} 6. Deploy
```bash
rpm-ostree rebase ...
systemctl reboot
```
:::

::::

## Architecture Overview

### Container-Based OS Image

```{admonition} Build Process
:class: tip

Bazzite AI builds bootable container images using:

1. **Base Image:** `ghcr.io/ublue-os/bazzite-nvidia-open:stable`
2. **Build Process:** Optimized Containerfile with layer caching
3. **Output:** Signed container image → GitHub Container Registry
```

### Build Script Execution

```{dropdown} Layered architecture for optimal caching
:open:

Each script executes in a separate Containerfile RUN layer:

**Layer 1-2:** System files and image metadata
**Layer 3:** Core Fedora packages (~500MB, stable)
**Layer 4:** External repos/COPR/VS Code/Docker (~100MB, moderate changes)
**Layer 5:** System configuration (~10MB, frequent changes)
**Layers 6-11:** Services, cleanup, finalization

**Performance:** Config-only changes rebuild in ~30-60 seconds vs. first build ~6-8 minutes.
```

## Testing Utilities

### Local ujust Recipe Testing

```{warning}
Bazzite AI is an **immutable OS** - the `/usr/` directory is read-only. Changes to justfiles only take effect after rebuilding and rebasing.
```

For rapid development, use the testing wrapper:

```bash
# Test without system modifications
./testing/ujust-test install-devcontainers-cli

# Or use usroverlay for full environment testing
sudo ./testing/apply-usroverlay.sh --transient
```

See {doc}`testing/index` for complete testing workflows.

## Key Files

### Build Configuration

```{list-table}
:header-rows: 1
:widths: 40 60

* - File
  - Purpose
* - `Containerfile`
  - OS image build definition
* - `Containerfile.containers`
  - Development container build (unified multi-stage)
* - `image-versions.yaml`
  - Base image tracking (managed by Renovate)
* - `iso.toml`
  - ISO installer configuration
* - `image.toml`
  - VM/raw image configuration
```

### Source Code

```{list-table}
:header-rows: 1
:widths: 40 60

* - Directory
  - Contents
* - `build_files/`
  - Build scripts executed during image build
* - `system_files/`
  - Files copied to OS root (configs, scripts, justfiles)
* - `docs/`
  - Documentation (this site!)
* - `testing/`
  - Testing utilities and guides
```

## CI/CD Pipeline

```{dropdown} GitHub Actions workflow

**Workflow:** `.github/workflows/build.yml`

1. **Setup:** Checkout code, BTRFS storage
2. **Build Optimizations:**
   - Buildah registry cache from GHCR
   - Direct file copies (no bind mounts)
   - 9 separate RUN layers for granular caching
3. **Fetch Base:** Pull `bazzite-nvidia-open:stable`
4. **Build OS:** Build unified KDE image
5. **Build Containers:** Parallel build with matrix strategy
6. **Tag:** Multiple patterns (latest, stable, version+date)
7. **Push:** To `ghcr.io/atrawog/`
8. **Sign:** With cosign (SIGNING_SECRET)
```

## Common Tasks

::::{tab-set}

:::{tab-item} Building
```bash
# OS image
just build

# ISOs
just build-iso

# Containers
just build-container
just build-container-nvidia

# VMs
just build-qcow2
just run-vm
```
:::

:::{tab-item} Testing
```bash
# Test ujust recipes locally
./testing/ujust-test <recipe>

# Test containers
just test-cuda-container

# Run VM for testing
just run-vm
```
:::

:::{tab-item} Maintenance
```bash
# Check justfile syntax
just check

# Auto-format justfiles
just fix

# Clean build artifacts
just clean
just sudo-clean
just release-clean
```
:::

::::

## Next Steps

::::{grid} 1 1 3 3
:gutter: 2

:::{grid-item-card} 🔨 Building
:link: building/index
:link-type: doc

ISO and VM image building
:::

:::{grid-item-card} 🧪 Testing
:link: testing/index
:link-type: doc

Testing guides and utilities
:::

:::{grid-item-card} 🤝 Contributing
:link: ../getting-started/contributing
:link-type: doc

Contribution guidelines
:::

::::

```{seealso}
- {doc}`../getting-started/index` - Installation and setup
- {doc}`../user-guide/index` - Using Bazzite AI
- [Universal Blue](https://universal-blue.org/) - Project foundation
```
