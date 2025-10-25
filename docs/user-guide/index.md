---
title: User Guide
---

# User Guide

Welcome to the Bazzite AI user guide! This section covers everything you need to know about using Bazzite AI for development, AI/ML workflows, and running applications.

## Topics Covered

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🐳 Container Development
:link: containers/index
:link-type: doc

Learn how to use Bazzite AI's development containers for isolated CPU and GPU workflows.
:::

:::{grid-item-card} 🎮 GPU Acceleration
:link: containers/gpu-setup
:link-type: doc

Set up NVIDIA GPU access for containers and AI/ML workloads.
:::

:::{grid-item-card} 🪟 Windows Apps
:link: winboat
:link-type: doc

Run Windows applications seamlessly with WinBoat integration.
:::

::::

## Quick Start Guides

### Container Development

Bazzite AI provides two development container variants:

::::{tab-set}

:::{tab-item} CPU-Only (Base)
Perfect for general development without GPU requirements.

```bash
# Using VS Code
code .
# Ctrl+Shift+P → "Reopen in Container"

# Using Apptainer (HPC/Research)
ujust apptainer-pull-container
ujust apptainer-run-container

# Using Podman directly
just pull-container
just run-container
```

[Learn more →](containers/usage.md)
:::

:::{tab-item} GPU Accelerated (NVIDIA)
Full CUDA support for AI/ML workflows.

```bash
# One-time GPU setup
ujust setup-gpu-containers

# Using VS Code (GPU auto-detected)
code .
# Ctrl+Shift+P → "Reopen in Container"

# Using Apptainer with GPU
ujust apptainer-pull-container-nvidia
ujust apptainer-run-container-nvidia

# Using Podman with GPU
just pull-container-nvidia
just run-container-nvidia
```

[GPU Setup Guide →](containers/gpu-setup.md)
:::

::::

### Windows Applications

```{admonition} WinBoat Integration
:class: tip

Run Windows applications natively on Bazzite AI with containerized Windows VM technology.
```

```bash
# Launch WinBoat GUI
winboat

# First-time setup downloads Windows container (~10GB)
# Then launch Windows apps as native Linux windows
```

[WinBoat Guide →](winboat.md)

## Container Platforms

Bazzite AI supports multiple container platforms for different use cases:

```{list-table}
:header-rows: 1
:widths: 25 35 40

* - Platform
  - Best For
  - Key Features
* - **Apptainer**
  - HPC, research, reproducibility
  - Single .sif files, rootless, native GPU
* - **VS Code Dev Containers**
  - IDE integration, development
  - Full VS Code features, extensions
* - **Podman/Docker**
  - Standalone containers, CI/CD
  - Standard OCI containers
* - **WinBoat**
  - Windows applications
  - Containerized Windows VM
```

## Common Workflows

::::{grid} 1 1 2 3
:gutter: 2

:::{grid-item-card} AI/ML Development
1. Set up GPU: `ujust setup-gpu-containers`
2. Pull NVIDIA container
3. Run Jupyter notebooks with CUDA
4. Train models with GPU acceleration
:::

:::{grid-item-card} Research Computing
1. Pull Apptainer container
2. Run with `--nv` for GPU
3. Share .sif files for reproducibility
4. Submit to HPC clusters
:::

:::{grid-item-card} Multi-Platform Dev
1. Use VS Code Dev Containers
2. Consistent environment across machines
3. Container-in-container support
4. Build/test in isolation
:::

::::

## System Integration

### Flatpak Applications

```bash
# Install all recommended apps
ujust install-flatpaks-all

# Or install by category
ujust install-flatpaks-dev         # VS Code, GitKraken, etc.
ujust install-flatpaks-productivity # Firefox, Chromium, LibreOffice
ujust install-flatpaks-media        # GIMP, Inkscape, Blender
```

### Development Tools

```bash
# Install pixi package manager + devcontainers CLI
ujust install-dev-tools

# Install Claude Code CLI
ujust install-claude-code

# Install extra fonts
ujust install-fonts
```

### Service Management

```bash
# Toggle SSH server
ujust toggle-sshd enable

# Toggle Docker daemon mode
ujust toggle-docker enable

# Toggle Game Mode (KDE only)
ujust toggle-gamemode desktop
```

## Next Steps

::::{grid} 1 1 3 3
:gutter: 2

:::{grid-item-card} 📦 Containers
:link: containers/index
:link-type: doc

Comprehensive container usage guide
:::

:::{grid-item-card} 🎮 GPU Setup
:link: containers/gpu-setup
:link-type: doc

NVIDIA GPU configuration
:::

:::{grid-item-card} 🪟 WinBoat
:link: winboat
:link-type: doc

Windows app integration
:::

::::

```{seealso}
- {doc}`../getting-started/index` - Installation and first steps
- {doc}`../developer-guide/index` - Building and contributing
- [Upstream Bazzite Docs](https://docs.bazzite.gg/) - Base system documentation
```
