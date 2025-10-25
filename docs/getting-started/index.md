---
title: Getting Started
---

# Getting Started with Bazzite AI

Welcome to Bazzite AI! This guide will help you get up and running with your AI/ML-optimized immutable Linux distribution.

## What is Bazzite AI?

```{admonition} Quick Overview
:class: tip

**Bazzite AI** is a container-based immutable Linux distribution built on Fedora Atomic Desktop, specifically designed for AI/ML development and research workflows. It extends [Bazzite](https://github.com/ublue-os/bazzite) with developer-focused tooling.
```

### Key Characteristics

::::{grid} 1 1 2 2
:gutter: 2

:::{grid-item-card} 🔒 Immutable OS
Atomic updates with rollback capability for stability and reproducibility.
:::

:::{grid-item-card} 🐳 Container-First
Development containers with CPU and GPU variants for isolated workflows.
:::

:::{grid-item-card} 🎮 GPU Accelerated
Full NVIDIA CUDA support with pre-installed nvidia-container-toolkit.
:::

:::{grid-item-card} 🛠️ Developer Ready
VS Code, Docker, Python, BPF tools, and comprehensive dev environment.
:::

::::

## Installation Options

```{warning}
Bazzite AI **only supports KDE Plasma variants**. GNOME variants are not officially supported.
```

### Option 1: Rebase from Existing Bazzite

If you already have Bazzite installed, you can rebase to Bazzite AI:

```bash
# Rebase to Bazzite AI (KDE Plasma unified variant)
rpm-ostree rebase ostree-unverified-registry:ghcr.io/atrawog/bazzite-ai:latest

# Reboot to apply changes
systemctl reboot
```

### Option 2: Clean ISO Installation

Download the latest ISO installer:

```{note}
ISOs are distributed via BitTorrent due to GitHub's 2GB file size limit.
```

1. **Download torrent file** from [GitHub Releases](https://github.com/atrawog/bazzite-ai/releases)
2. **Open with BitTorrent client** (Transmission, qBittorrent, etc.)
3. **Verify checksum** after download
4. **Create bootable USB** with tools like Ventoy or Rufus
5. **Boot and install**

### Option 3: Virtual Machine Testing

Test Bazzite AI in a VM before committing:

```bash
# Pull the latest container image
just pull

# Build QCOW2 image
just build-qcow2

# Run in browser-based viewer
just run-vm
```

The VM will be available at `http://localhost:8006+` with 4 cores, 8GB RAM, and 64GB disk.

## First Steps After Installation

### 1. System Update

```bash
# Update to latest version
ujust update

# Or manually
rpm-ostree upgrade
```

### 2. Install Flatpak Applications

```bash
# Install all recommended flatpaks
ujust install-flatpaks-all

# Or install by category
ujust install-flatpaks-dev              # Development tools
ujust install-flatpaks-productivity     # Browsers & office
ujust install-flatpaks-media            # Media & graphics
```

See the complete list of available categories:
```bash
ujust --list | grep flatpaks
```

### 3. Set Up Development Tools

```bash
# Install pixi package manager + devcontainers CLI
ujust install-dev-tools

# Or install individually
ujust install-pixi
ujust install-devcontainers-cli
```

### 4. Configure GPU Access (NVIDIA only)

If using NVIDIA GPU with containers:

```bash
# One-time GPU container setup
ujust setup-gpu-containers
```

See {doc}`../user-guide/containers/gpu-setup` for details.

### 5. Install Additional Fonts

```bash
# Install extra fonts via Homebrew
ujust install-fonts
```

## Available Commands

Bazzite AI provides numerous `ujust` commands for system management:

::::{tab-set}

:::{tab-item} System
```bash
ujust update                    # System update
ujust toggle-gamemode           # Toggle Steam Game Mode (KDE only)
ujust toggle-sshd               # Enable/disable SSH server
ujust toggle-docker             # Toggle Docker daemon mode
```
:::

:::{tab-item} Development
```bash
ujust install-pixi              # Install pixi package manager
ujust install-devcontainers-cli # Install devcontainers CLI
ujust install-dev-tools         # Install both above
ujust install-claude-code       # Install Claude Code CLI
```
:::

:::{tab-item} Applications
```bash
ujust install-flatpaks-all      # Install all flatpaks
ujust install-flatpaks-dev      # Development tools
ujust install-flatpaks-media    # Media & graphics
ujust install-fonts             # Extra fonts
```
:::

:::{tab-item} Containers
```bash
ujust setup-gpu-containers      # One-time GPU setup (NVIDIA)
ujust apptainer-pull-container  # Download Apptainer container
ujust apptainer-run-container   # Run Apptainer interactively
```
:::

::::

## Next Steps

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 📖 User Guide
:link: ../user-guide/index
:link-type: doc

Learn about container development, GPU acceleration, and Windows app support.
:::

:::{grid-item-card} 💻 Developer Guide
:link: ../developer-guide/index
:link-type: doc

Build ISOs, create releases, and contribute to the project.
:::

:::{grid-item-card} 🤝 Contributing
:link: contributing
:link-type: doc

Learn how to contribute code, report issues, and sync with upstream.
:::

:::{grid-item-card} 🐛 Report Issues
:link: https://github.com/atrawog/bazzite-ai/issues

Found a bug? Open an issue on GitHub.
:::

::::

## Additional Resources

```{seealso}
- [Bazzite Documentation](https://docs.bazzite.gg/) - Upstream documentation
- [Universal Blue](https://universal-blue.org/) - Project foundation
- [Fedora Atomic Desktops](https://fedoraproject.org/atomic-desktops/) - Base platform
```
