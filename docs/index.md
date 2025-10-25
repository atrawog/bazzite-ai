---
title: Bazzite AI Documentation
---

# Welcome to Bazzite AI

```{image} _static/logo.png
:alt: Bazzite AI Logo
:class: only-light
:width: 200px
:align: center
```

**Bazzite AI** is a custom fork of [Bazzite](https://github.com/ublue-os/bazzite) with AI/ML-focused tooling and customizations. It's a container-based immutable Linux distribution built on top of Bazzite, extending it with developer tooling optimized for AI/ML workflows.

```{note}
Bazzite AI **only supports KDE Plasma variants**. GNOME variants are not officially supported.
```

## Quick Links

::::{grid} 2
:gutter: 3

:::{grid-item-card} 🚀 Getting Started
:link: getting-started/index
:link-type: doc

New to Bazzite AI? Start here to learn the basics and set up your environment.
:::

:::{grid-item-card} 📖 User Guide
:link: user-guide/index
:link-type: doc

Learn how to use containers, GPU acceleration, and Windows apps with WinBoat.
:::

:::{grid-item-card} 💻 Developer Guide
:link: developer-guide/index
:link-type: doc

Build ISOs, manage releases, and contribute to the project.
:::

:::{grid-item-card} 🧪 Testing
:link: developer-guide/testing/index
:link-type: doc

Comprehensive testing guides for containers and system components.
:::

::::

## Key Features

::::{grid} 1 1 2 3
:gutter: 2

:::{grid-item-card} 🐳 Container Development
Pre-configured development containers with CPU and GPU variants for isolated AI/ML workflows.
:::

:::{grid-item-card} 🎮 GPU Acceleration
Full CUDA support with nvidia-container-toolkit for ML/AI workloads.
:::

:::{grid-item-card} 🪟 Windows Apps
Run Windows applications seamlessly with WinBoat integration.
:::

:::{grid-item-card} 📦 Apptainer Support
HPC-style container workflows for research and scientific computing.
:::

:::{grid-item-card} 🛠️ Developer Tools
VS Code, Docker, BPF tools, Android tools, and comprehensive development environment.
:::

:::{grid-item-card} 🔒 Immutable OS
Container-based OSTree image builds for reliable and reproducible systems.
:::

::::

## Architecture Overview

```{admonition} Container-Based OS Image
:class: tip

Bazzite AI builds bootable container images using:

1. **Base Image**: `ghcr.io/ublue-os/bazzite-nvidia-open:stable` (unified base)
2. **Build Process**: Optimized Containerfile with layer caching for 40-60% faster builds
3. **Output**: Signed container image pushed to GitHub Container Registry

**Performance:** Incremental config changes rebuild in ~30-60 seconds vs. first build ~6-8 minutes.
```

### Technology Stack

```{list-table}
:header-rows: 1
:widths: 30 70

* - Component
  - Technology
* - **Base**
  - Fedora Atomic Desktop with ublue-os/bazzite-nvidia-open
* - **Desktop**
  - KDE Plasma only
* - **Build System**
  - Containerfile-based OSTree image builds
* - **Task Runner**
  - Just (justfile)
* - **Package Managers**
  - dnf5, flatpak, homebrew (fonts)
* - **Container Tools**
  - Apptainer, Podman/Docker, WinBoat
* - **CI/CD**
  - GitHub Actions with buildah/cosign signing
```

## What's Different from Base Bazzite?

```{dropdown} Developer-focused changes for KDE Plasma
:open:

1. **Removed Gaming Defaults**
   - Disabled autologin to Steam Game Mode
   - Re-enabled SDDM login screens and user switching

2. **Added Developer Tools**
   - VS Code (Microsoft repo)
   - Docker CE + docker-compose
   - BPF tools (bpftrace, bpftop, bcc)
   - nvidia-container-toolkit (always installed)
   - Android tools, cloud tools, Python ramalama

3. **Enabled Services**
   - input-remapper, uupd.timer, ublue-setup-services
```

## Container Variants

Bazzite AI provides **two development container images** for isolated development:

::::{tab-set}

:::{tab-item} Base Container (CPU)
**bazzite-ai-container** - Clean CPU-only development container

- Fedora 42 with all development tools
- No NVIDIA/CUDA dependencies
- Safe isolated environment for Claude Code
- Perfect for systems without GPUs

**Image:** `ghcr.io/atrawog/bazzite-ai-container`

[Learn more →](user-guide/containers/usage.md)
:::

:::{tab-item} NVIDIA Container (GPU)
**bazzite-ai-container-nvidia** - GPU-accelerated development container

- Built on base container + cuDNN + TensorRT
- Full CUDA acceleration
- ML/AI workloads with GPU support
- Uses host CUDA runtime via nvidia-container-toolkit

**Image:** `ghcr.io/atrawog/bazzite-ai-container-nvidia`

[GPU Setup Guide →](user-guide/containers/gpu-setup.md)
:::

::::

## Getting Help

::::{grid} 1 1 2 2
:gutter: 2

:::{grid-item-card} 📚 Documentation
Browse the comprehensive guides in this documentation site.
:::

:::{grid-item-card} 🐛 Report Issues
Found a bug? [Open an issue](https://github.com/atrawog/bazzite-ai/issues) on GitHub.
:::

:::{grid-item-card} 💬 Discussions
Ask questions and share ideas in [GitHub Discussions](https://github.com/atrawog/bazzite-ai/discussions).
:::

:::{grid-item-card} 🤝 Contribute
Read the {doc}`getting-started/contributing` guide to get started.
:::

::::
