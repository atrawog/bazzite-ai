---
title: Container Development
---

# Container Development

Bazzite AI provides comprehensive container support for isolated development workflows with both CPU and GPU acceleration options.

## Overview

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🐳 Base Container (CPU)
:link: usage
:link-type: doc

Clean CPU-only development environment with all tools, no NVIDIA dependencies.

**Image:** `ghcr.io/atrawog/bazzite-ai-container`
:::

:::{grid-item-card} 🎮 NVIDIA Container (GPU)
:link: usage
:link-type: doc

GPU-accelerated container with cuDNN and TensorRT for AI/ML workloads.

**Image:** `ghcr.io/atrawog/bazzite-ai-container-nvidia`
:::

::::

## Quick Start

Choose your preferred platform:

::::{tab-set}

:::{tab-item} Apptainer (HPC/Research)
**Recommended for:** Scientific computing, reproducible research, HPC clusters

```bash
# CPU-only
ujust apptainer-pull-container
ujust apptainer-run-container

# GPU-accelerated (NVIDIA)
ujust apptainer-pull-container-nvidia
ujust apptainer-run-container-nvidia
```

**Benefits:**
- Single `.sif` files for easy sharing
- No daemon required
- Native GPU support with `--nv`
- Standard in academic/research environments
:::

:::{tab-item} VS Code Dev Containers
**Recommended for:** IDE-integrated development, full-featured environment

```bash
# Open in VS Code
code .

# Command Palette (Ctrl+Shift+P)
# → "Dev Containers: Reopen in Container"
```

**Benefits:**
- Full IDE integration
- Extension support
- Container-in-container workflows
- Auto-detects GPU availability
:::

:::{tab-item} Podman/Docker
**Recommended for:** Standalone containers, automation, CI/CD

```bash
# CPU-only
just pull-container
just run-container

# GPU-accelerated (NVIDIA)
just pull-container-nvidia
just run-container-nvidia
```

**Benefits:**
- Standard OCI containers
- Integration with existing workflows
- Direct control over container runtime
:::

::::

## Container Variants

### Base Container (CPU-Only)

```{admonition} Clean separation
:class: tip

The base container has **zero** NVIDIA/CUDA dependencies, making it smaller and perfect for CPU-only development.
```

**Features:**
- Fedora 42 base
- All development tools (VS Code, Docker, Python, Node.js, BPF tools, etc.)
- No GPU overhead
- Perfect for Claude Code with `--dangerously-skip-permissions`

**Use Cases:**
- General software development
- Systems without GPUs
- Lightweight isolated environments
- Base layer for NVIDIA variant

[Complete Usage Guide →](usage.md)

### NVIDIA Container (GPU)

```{admonition} Layered architecture
:class: tip

Built **on top** of the base container, adding only GPU-specific libraries (cuDNN, TensorRT). This ensures efficient builds and maximum layer reuse.
```

**Features:**
- Everything from base container
- cuDNN and TensorRT pre-installed
- Full CUDA acceleration
- Uses host CUDA runtime via nvidia-container-toolkit

**Use Cases:**
- AI/ML development and training
- CUDA-accelerated applications
- GPU computing and research
- Deep learning frameworks

**Requirements:**
- Must use bazzite-ai (KDE only)
- nvidia-container-toolkit (pre-installed)
- One-time CDI setup: `ujust setup-gpu-containers`

[GPU Setup Guide →](gpu-setup.md)

## Platform Comparison

```{list-table}
:header-rows: 1
:widths: 20 25 25 30

* - Feature
  - Apptainer
  - VS Code
  - Podman/Docker
* - **GPU Support**
  - Native (`--nv`)
  - Auto-detected
  - Via CDI
* - **Reproducibility**
  - Excellent (.sif)
  - Good
  - Good
* - **IDE Integration**
  - Terminal only
  - Full VS Code
  - External
* - **Rootless**
  - Yes (default)
  - Yes
  - Yes
* - **HPC Clusters**
  - ✅ Standard
  - ❌ Not typical
  - ⚠️ Limited
* - **Setup Complexity**
  - Low
  - Medium
  - Medium
```

## Common Workflows

::::{dropdown} AI/ML Model Training (GPU)
:open:

```bash
# 1. Set up GPU access (one-time)
ujust setup-gpu-containers

# 2. Pull NVIDIA container
ujust apptainer-pull-container-nvidia
# OR for VS Code: code . → "Reopen in Container"

# 3. Inside container
cd /workspace
nvidia-smi  # Verify GPU

# 4. Train your model
python train.py
```
::::

::::{dropdown} Reproducible Research
```bash
# Create reproducible environment
apptainer pull docker://ghcr.io/atrawog/bazzite-ai-container-nvidia:20251022

# Run experiments
apptainer exec --nv --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container-nvidia_20251022.sif \
  python experiment.py

# Share .sif file with collaborators
# Everyone uses identical environment!
```
::::

::::{dropdown} Multi-Platform Development
```bash
# Same container on:
# - Local workstation
# - Remote server (SSH)
# - HPC cluster
# - CI/CD pipeline

# Always consistent environment!
```
::::

## Next Steps

::::{grid} 1 1 3 3
:gutter: 2

:::{grid-item-card} 📖 Usage Guide
:link: usage
:link-type: doc

Comprehensive container usage documentation
:::

:::{grid-item-card} 🎮 GPU Setup
:link: gpu-setup
:link-type: doc

Configure NVIDIA GPU access
:::

:::{grid-item-card} 🐛 Troubleshooting
:link: usage
:link-type: doc

See the troubleshooting section in the usage guide

Common issues and solutions
:::

::::

```{seealso}
- {doc}`../../developer-guide/testing/container-testing` - Container testing guide
- [Apptainer Documentation](https://apptainer.org/docs/) - Official Apptainer docs
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) - Microsoft documentation
```
