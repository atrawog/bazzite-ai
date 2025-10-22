# Bazzite AI

[![Build Bazzite AI](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml/badge.svg)](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml)

This is a custom fork of [Bazzite DX](https://github.com/ublue-os/bazzite-dx) with AI/ML-focused tooling and customizations, building on top of Bazzite with extra developer-specific tools.

**⚠️ Important**: Bazzite AI **only supports KDE Plasma**. GNOME variants are not officially supported.

## Variants

Bazzite AI provides **2 OS images** and **1 devcontainer image**:

### OS Images (KDE Plasma)
- **bazzite-ai** - For AMD/Intel GPUs
- **bazzite-ai-nvidia** - For NVIDIA GPUs with container GPU support

### Devcontainer
- **bazzite-ai-devcontainer** - CUDA-enabled development container
  - Safe isolated environment for AI/ML development
  - Full GPU acceleration via NVIDIA Container Toolkit
  - Perfect for Claude Code with `--dangerously-skip-permissions`
  - All development tools from bazzite-ai-nvidia

See [Devcontainer Guide](#devcontainer) below for details.

## Installation

### Fresh Installation (ISO)

Download the latest ISO from [Releases](https://github.com/atrawog/bazzite-ai/releases/latest):

- **bazzite-ai-*.iso** - For AMD/Intel GPUs
- **bazzite-ai-nvidia-*.iso** - For NVIDIA GPUs

Create a bootable USB drive using your preferred tool:
- [Fedora Media Writer](https://fedoraproject.org/workstation/download) (Recommended)
- [balenaEtcher](https://etcher.balena.io/)
- [Ventoy](https://www.ventoy.net/)

Boot from the USB drive and follow the installation prompts.

### Rebase from Existing Bazzite

To rebase an existing Bazzite installation to Bazzite AI:

**For AMD/Intel GPUs (KDE Plasma):**
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/atrawog/bazzite-ai:stable
```

**For NVIDIA GPUs (KDE Plasma):**
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/atrawog/bazzite-ai-nvidia:stable
```

After running the rebase command, reboot your system to complete the installation.

**Note:** To skip signature verification (not recommended), replace `ostree-image-signed:docker://ghcr.io` with `ostree-unverified-registry:ghcr.io`.

## Devcontainer

For isolated development, use **bazzite-ai-devcontainer**:

### Quick Start with VS Code

```bash
# 1. Open repository in VS Code
code /path/to/bazzite-ai

# 2. Command Palette (Ctrl+Shift+P) → "Reopen in Container"
# 3. GPU is automatically detected!
```

**One unified configuration** that works on both GPU and non-GPU systems. Uses the latest pre-built image from GitHub Container Registry.

### Standalone Usage

```bash
# Pull pre-built image
just pull-devcontainer

# Run with GPU
just run-devcontainer

# Or CPU-only mode
just run-devcontainer-no-gpu
```

### Benefits

- **Safe Isolation**: Run Claude Code with `--dangerously-skip-permissions` safely
- **CUDA Support**: Full GPU acceleration for AI/ML workloads
- **All Tools**: VS Code, Docker, Python, Node.js, BPF tools, and more
- **Consistent**: Same environment across all machines

### Requirements

**For GPU acceleration**:
- Must use **bazzite-ai-nvidia** (KDE variant) as host
- Run `ujust setup-gpu-containers` once to enable GPU passthrough

**Documentation**:
- [Devcontainer Guide](docs/DEVCONTAINER.md) - Complete usage guide
- [GPU Setup](docs/HOST-SETUP-GPU.md) - Host GPU configuration

## Acknowledgments

This project is built upon the work from [amyos](https://github.com/astrovm/amyos)

## Metrics

![Alt](https://repobeats.axiom.co/api/embed/8568b042f7cfba9dd477885ed5ee6573ab78bb5e.svg "Repobeats analytics image")
