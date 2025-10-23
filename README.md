# Bazzite AI

[![Build Bazzite AI](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml/badge.svg)](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml)

This is a custom fork of [Bazzite DX](https://github.com/ublue-os/bazzite-dx) with AI/ML-focused tooling and customizations, building on top of Bazzite with extra developer-specific tools.

**⚠️ Important**: Bazzite AI **only supports KDE Plasma**. GNOME variants are not officially supported.

## Variants

Bazzite AI provides **1 unified OS image** and **2 container images**:

### OS Image (KDE Plasma)
- **bazzite-ai** - Unified image for all hardware (AMD/Intel/NVIDIA)
  - Based on bazzite-nvidia-open (open NVIDIA drivers work on all GPUs)
  - NVIDIA Container Toolkit pre-installed
  - Full GPU acceleration support for containers
  - Seamless experience regardless of hardware

### Container Images
- **bazzite-ai-container** - Base CPU-only development container
  - Clean Fedora 42 base with all dev tools
  - No NVIDIA/CUDA dependencies
  - Perfect for CPU-only development
- **bazzite-ai-container-nvidia** - GPU-accelerated container (builds on base)
  - Adds cuDNN and TensorRT for ML acceleration
  - Full GPU acceleration via NVIDIA Container Toolkit
  - Safe isolated environment for AI/ML development
  - Perfect for Claude Code with `--dangerously-skip-permissions`

See [Container Guide](#development-container) below for details.

## Installation

### Fresh Installation (ISO)

Download the latest ISO from [Releases](https://github.com/atrawog/bazzite-ai/releases/latest):

- **bazzite-ai-*.iso** - Unified ISO for all hardware (AMD/Intel/NVIDIA)

Create a bootable USB drive using your preferred tool:
- [Fedora Media Writer](https://fedoraproject.org/workstation/download) (Recommended)
- [balenaEtcher](https://etcher.balena.io/)
- [Ventoy](https://www.ventoy.net/)

Boot from the USB drive and follow the installation prompts.

### Rebase from Existing Bazzite

To rebase an existing Bazzite installation to Bazzite AI:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/atrawog/bazzite-ai:stable
```

After running the rebase command, reboot your system to complete the installation.

**Note:** To skip signature verification (not recommended), replace `ostree-image-signed:docker://ghcr.io` with `ostree-unverified-registry:ghcr.io`.

## Development Container

Bazzite AI provides two container variants for isolated development:

- **bazzite-ai-container** - Base CPU-only container
- **bazzite-ai-container-nvidia** - GPU-accelerated container with cuDNN/TensorRT

### Quick Start with Apptainer (Recommended for HPC/Research)

Apptainer provides single-file containers (.sif) ideal for reproducible research:

#### GPU Development (NVIDIA)

```bash
# 1. Pull the NVIDIA container
ujust apptainer-pull-container-nvidia

# 2. Run with GPU support (auto-detected)
ujust apptainer-run-container-nvidia

# 3. Your workspace is mounted at /workspace
# Inside container:
cd /workspace
nvidia-smi  # Test GPU
```

#### CPU-Only Development

```bash
# 1. Pull the base container
ujust apptainer-pull-container

# 2. Run without GPU
ujust apptainer-run-container

# 3. Your workspace is mounted at /workspace
# Inside container:
cd /workspace
python script.py  # Run your code
```

**Benefits:**
- ✅ Single .sif file - easy to archive and share
- ✅ Native GPU support via `--nv` (no setup needed)
- ✅ HPC/cluster friendly (no daemon, no root)
- ✅ Auto-mounts your workspace directory
- ✅ Separate base/nvidia containers for optimal efficiency

### Alternative: VS Code Dev Containers

For VS Code users, traditional Docker/Podman workflow:

#### GPU Development
```bash
# 1. Open repository in VS Code
code /path/to/bazzite-ai

# 2. Command Palette (Ctrl+Shift+P) → "Reopen in Container"
# 3. GPU automatically detected (uses NVIDIA variant)
```

#### CPU-Only Development
```bash
# 1. Open repository in VS Code
code /path/to/bazzite-ai

# 2. Open Container Configuration File
# Command Palette → "Open Container Configuration File"
# Select .devcontainer/devcontainer-base.json

# 3. Command Palette → "Reopen in Container"
```

Uses pre-built images from GitHub Container Registry.

### Manual Apptainer Usage

```bash
# GPU Development
ujust apptainer-pull-container-nvidia stable
ujust apptainer-run-container-nvidia latest /path/to/project
ujust apptainer-exec-container-nvidia "python train.py"

# CPU-Only Development
ujust apptainer-pull-container stable
ujust apptainer-run-container latest /path/to/project
```

### Container Features

**Base Container (bazzite-ai-container)**:
- Clean Fedora 42 base with all dev tools
- VS Code, Docker, Python, Node.js, Claude Code
- No NVIDIA/CUDA overhead
- Perfect for CPU-only development

**NVIDIA Container (bazzite-ai-container-nvidia)**:
- Everything from base container
- cuDNN and TensorRT for ML acceleration
- Full CUDA support for GPU workloads
- Safe isolation for `claude --dangerously-skip-permissions`

### Requirements

**For GPU acceleration (Apptainer)**:
- NVIDIA GPU with drivers (pre-configured in bazzite-ai)
- No additional setup needed - Apptainer handles GPU automatically

**For GPU acceleration (Podman/Docker)**:
- NVIDIA GPU with drivers (pre-configured in bazzite-ai)
- Run `ujust setup-gpu-containers` once for CDI config
- nvidia-container-toolkit is pre-installed

**For CPU-only**: Works on all hardware (AMD/Intel/NVIDIA).

See [CONTAINER.md](docs/CONTAINER.md) for comprehensive guide.

## Running Windows Applications

**WinBoat** allows you to run Windows software natively on bazzite-ai:

### Quick Start

```bash
# 1. Launch WinBoat
winboat

# 2. Follow setup wizard to configure Windows container
# 3. Launch Windows apps from WinBoat interface
```

### Features

- **Seamless Integration**: Windows apps appear as native Linux windows
- **File Sharing**: Home directory accessible from Windows
- **Full Desktop**: Access complete Windows desktop when needed
- **Containerized**: Windows runs in isolated Docker container

### Requirements

- Minimum 4GB RAM (8GB+ recommended)
- 32GB free disk space for Windows container
- KVM virtualization enabled (pre-configured in bazzite-ai)

### Use Cases

- Run Windows-only applications (Adobe, AutoCAD, etc.)
- Test Windows software without dual-boot
- Access Windows development tools
- Legacy Windows application support

**Note**: WinBoat is beta software. Expect occasional issues.

See [WinBoat Documentation](https://github.com/TibixDev/winboat) for details.

## Acknowledgments

This project is built upon the work from [amyos](https://github.com/astrovm/amyos)

## Metrics

![Alt](https://repobeats.axiom.co/api/embed/8568b042f7cfba9dd477885ed5ee6573ab78bb5e.svg "Repobeats analytics image")
