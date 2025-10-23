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

## Development Container

For isolated AI/ML development, use **bazzite-ai-devcontainer**:

### Quick Start with Apptainer (Recommended for HPC/Research)

Apptainer provides single-file containers (.sif) ideal for reproducible research:

```bash
# 1. Pull the devcontainer
ujust apptainer-pull-devcontainer

# 2. Run with GPU support (auto-detected)
ujust apptainer-run-devcontainer

# 3. Your workspace is mounted at /workspace
# Inside container:
cd /workspace
nvidia-smi  # Test GPU
```

**Benefits:**
- ✅ Single .sif file - easy to archive and share
- ✅ Native GPU support via `--nv` (no setup needed)
- ✅ HPC/cluster friendly (no daemon, no root)
- ✅ Auto-mounts your workspace directory

### Alternative: VS Code Dev Containers

For VS Code users, traditional Docker/Podman workflow:

```bash
# 1. Open repository in VS Code
code /path/to/bazzite-ai

# 2. Command Palette (Ctrl+Shift+P) → "Reopen in Container"
# 3. GPU automatically detected
```

Uses pre-built image from GitHub Container Registry.

### Manual Apptainer Usage

```bash
# Pull specific version
ujust apptainer-pull-devcontainer stable

# Run with custom workspace
ujust apptainer-run-devcontainer latest /path/to/project

# CPU-only mode
ujust apptainer-run-devcontainer-cpu

# Execute single command
ujust apptainer-exec-devcontainer "python train.py"
```

### Container Features

- **Full CUDA Support**: GPU acceleration for AI/ML workloads
- **All Dev Tools**: VS Code, Docker, Python, Node.js, Claude Code, and more
- **Safe Isolation**: Run `claude --dangerously-skip-permissions` safely
- **Consistent Environment**: Same tools across all machines

### Requirements

**For GPU acceleration (Apptainer)**:
- Must use **bazzite-ai-nvidia** (KDE variant) as host
- NVIDIA drivers installed (pre-configured in bazzite-ai-nvidia)
- No additional setup needed - Apptainer handles GPU automatically

**For GPU acceleration (Podman/Docker)**:
- Must use **bazzite-ai-nvidia** (KDE variant)
- Run `ujust setup-gpu-containers` once for CDI config

**For CPU-only**: Works on any bazzite-ai variant.

See [DEVCONTAINER.md](docs/DEVCONTAINER.md) for comprehensive guide.

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
