# Bazzite AI

[![Build Bazzite AI](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml/badge.svg)](https://github.com/atrawog/bazzite-ai/actions/workflows/build.yml)

This is a customized overlay image based on [Bazzite](https://github.com/ublue-os/bazzite) with comprehensive GPU support (NVIDIA/AMD/Intel) and AI/ML-focused tooling, extending Bazzite with developer-specific tools and configurations.

**⚠️ Important**: Bazzite AI **only supports KDE Plasma**. GNOME variants are not officially supported.

## Variants

Bazzite AI provides **1 unified OS image** and **2 container images**:

### OS Image (KDE Plasma)
- **bazzite-ai** - Unified image for all hardware (AMD/Intel/NVIDIA)
  - Based on bazzite-nvidia-open with comprehensive GPU driver support
  - **NVIDIA:** Open kernel modules (RTX 20 series and newer)
  - **AMD:** AMDGPU open-source driver (GCN 1+ and RDNA 1-4)
  - **Intel:** i915/xe drivers (Gen 7+ integrated and Arc discrete)
  - Pre-configured with nvidia-container-toolkit for GPU containers
  - Mesa 25.2.4 with Vulkan 1.4 support
  - Seamless experience regardless of GPU vendor

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

## GPU Compatibility

Bazzite AI includes comprehensive GPU support for all modern graphics hardware through open-source drivers.

### Driver Stack

- **Graphics API:** Mesa 25.2.4 (OpenGL, Vulkan 1.4)
- **Kernel:** 6.16.4 with latest GPU drivers
- **NVIDIA:** Open kernel modules 580.95.05 (MIT/GPL)
- **AMD:** AMDGPU kernel driver + Mesa RADV
- **Intel:** i915/xe kernel drivers + Mesa ANV

### NVIDIA GPUs (Open Kernel Modules)

| Architecture | GPU Series | Release | Support Status |
|-------------|------------|---------|----------------|
| **Blackwell** | RTX 50 series | 2025 | ✅ **Required** (open-source only) |
| **Ada Lovelace** | RTX 40 series | 2022 | ✅ **Recommended** |
| **Ampere** | RTX 30 series | 2020 | ✅ **Recommended** |
| **Turing** | RTX 20, GTX 16 series | 2018 | ✅ **Recommended** |
| **Volta** | Titan V, datacenter | 2017 | ❌ Not supported (use proprietary) |
| **Pascal** | GTX 10 series | 2016 | ❌ Not supported (use proprietary) |
| **Maxwell** | GTX 900/700 series | 2014 | ❌ Not supported (use proprietary) |

**Note:** NVIDIA's open drivers are now the default for Turing and newer GPUs, offering equivalent or better performance than proprietary drivers.

### AMD GPUs (AMDGPU + Mesa RADV)

| Architecture | GPU Series | Release | Support Status |
|-------------|------------|---------|----------------|
| **RDNA 4** | RX 9000 series | 2025 | ✅ **Full support** |
| **RDNA 3** | RX 7000 series | 2022 | ✅ **Full support** |
| **RDNA 2** | RX 6000 series | 2020 | ✅ **Full support** |
| **RDNA 1** | RX 5000/5500 series | 2019 | ✅ **Full support** |
| **GCN 5** | RX Vega series | 2017 | ✅ **Full support** |
| **GCN 4** | RX 400/500 series | 2016 | ✅ **Full support** |
| **GCN 3** | R9 Fury/Nano series | 2015 | ✅ **Full support** |
| **GCN 2** | HD 8000 series | 2013 | ⚠️ Requires kernel params |
| **GCN 1** | HD 7000 series | 2012 | ⚠️ Requires kernel params |
| **Pre-GCN** | HD 6000 and older | <2012 | ❌ Not supported |

**Note:** All modern AMD GPUs use the open-source AMDGPU driver with excellent performance.

### Intel GPUs (i915/xe + Mesa ANV)

| Architecture | GPU Series | Release | Driver | Support Status |
|-------------|------------|---------|--------|----------------|
| **Battlemage** | Arc B-series | 2024-2025 | **xe** | ✅ **Full support** (kernel 6.12+) |
| **Lunar Lake** | Core Ultra 200V | 2024 | **xe** | ✅ **Full support** |
| **Alchemist** | Arc A-series | 2022 | **i915** | ✅ **Recommended** (AV1 encoding) |
| **Gen 12** | Tiger/Alder/Raptor Lake | 2020-2023 | **i915** | ✅ **Full support** |
| **Gen 11** | Ice Lake | 2019 | **i915** | ✅ **Full support** |
| **Gen 9** | Skylake/Kaby/Coffee Lake | 2015-2018 | **i915** | ✅ **Full support** |
| **Gen 8** | Broadwell | 2014 | **i915** | ✅ **Full support** |
| **Gen 7** | Haswell/Ivy Bridge | 2012-2013 | **i915** | ✅ **Full support** |
| **Gen 6** | Sandy Bridge | 2011 | N/A | ❌ Not supported |

**Note:** Bazzite AI includes both i915 (stable, default for Arc Alchemist) and xe (modern, default for Battlemage+) drivers. The system automatically selects the appropriate driver.

### Why Bazzite AI Works on All Hardware

Bazzite AI is based on **bazzite-nvidia-open** which includes:
- ✅ **NVIDIA open drivers** for modern NVIDIA GPUs (RTX 20 series and newer)
- ✅ **AMDGPU/Mesa drivers** work seamlessly on AMD hardware
- ✅ **Intel i915/xe drivers** work seamlessly on Intel hardware
- ✅ **No conflicts** - unused drivers are simply not loaded

The "nvidia-open" base doesn't prevent use on AMD/Intel systems - it ensures NVIDIA users get optimal support while maintaining full compatibility with all GPU vendors.

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

## Virtualization

Bazzite AI includes comprehensive virtualization support pre-configured and ready to use:

### What's Included

- ✅ **libvirtd service** - Enabled at boot for VM management
- ✅ **virt-manager** - Pre-installed GUI for creating and managing VMs
- ✅ **QEMU/KVM** - Full hardware virtualization support
- ✅ **libvirt group** - Users auto-added for sudo-free VM management
- ✅ **KVM kernel args** - Automatically added on first boot for optimal VM compatibility

### Quick Start

```bash
# Check virtualization status
ujust toggle-libvirtd status

# Open virt-manager from application menu
# Create VMs without any additional setup required
```

### KVM Kernel Arguments

On first boot, Bazzite AI automatically adds kernel arguments for better VM compatibility:
- `kvm.ignore_msrs=1` - Allows VMs to ignore unsupported CPU registers
- `kvm.report_ignored_msrs=0` - Reduces kernel log spam

A reboot is required after first boot for these args to take effect.

### Advanced Features

For GPU passthrough, Looking Glass, or VFIO:

```bash
ujust setup-virtualization help
```

See the [Virtualization Guide](https://atrawog.github.io/bazzite-ai/user-guide/virtualization.html) for complete documentation.

## Acknowledgments

This project is built upon the work from [amyos](https://github.com/astrovm/amyos)

## Metrics

![Alt](https://repobeats.axiom.co/api/embed/8568b042f7cfba9dd477885ed5ee6573ab78bb5e.svg "Repobeats analytics image")
