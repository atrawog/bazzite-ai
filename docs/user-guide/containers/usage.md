---
title: Container Usage Guide
---

# Container Usage Guide

Complete guide to using Bazzite AI development containers for isolated CPU and GPU workflows.

## Overview

Bazzite AI provides **two development container variants** for isolated development work:

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} bazzite-ai-container
**Base CPU-only container**

Clean image with no NVIDIA/CUDA dependencies

- Fedora 42 + all dev tools
- Lightweight, smaller size
- Perfect for Claude Code
- Base layer for NVIDIA variant

**Image:** `ghcr.io/atrawog/bazzite-ai-container`
:::

:::{grid-item-card} bazzite-ai-container-nvidia
**GPU-accelerated container**

Builds on base + cuDNN + TensorRT

- Everything from base
- ML libraries pre-installed
- Full CUDA acceleration
- Host CUDA runtime passthrough

**Image:** `ghcr.io/atrawog/bazzite-ai-container-nvidia`

{bdg-warning}`Requires GPU setup`
:::

::::

### Key Features

```{list-table}
:header-rows: 1
:widths: 40 60

* - Feature
  - Description
* - **Dual Architecture**
  - Separate CPU and GPU containers for optimal efficiency
* - **All Dev Tools**
  - VS Code, Docker, Python, Node.js, BPF tools, Android tools
* - **Safe Isolation**
  - Perfect for `--dangerously-skip-permissions` with Claude Code
* - **Container-in-Container**
  - Docker socket mount for nested builds
* - **Pre-built Images**
  - Auto-built via GitHub Actions, pull from GHCR
* - **VS Code Native**
  - Full Dev Containers support
* - **GPU Support**
  - Full CUDA acceleration (nvidia variant only)
```

### Use Cases

::::{grid} 1 1 2 3
:gutter: 2

:::{grid-item-card} 🤖 Claude Code Development
Safe isolated environment for AI-assisted coding
:::

:::{grid-item-card} 🎮 CUDA/GPU Development
ML/AI workloads with full GPU acceleration
:::

:::{grid-item-card} 🌐 Multi-platform Development
Consistent environment across machines
:::

:::{grid-item-card} 🧪 Experimentation
Test changes without affecting host
:::

:::{grid-item-card} 🔬 HPC/Research
Reproducible environments via Apptainer
:::

::::

## Quick Start by Platform

### Option A: Apptainer (Recommended for HPC/Research)

```{admonition} Best for
:class: tip

Scientific computing, HPC clusters, reproducible research with single .sif files
```

::::{tab-set}

:::{tab-item} GPU Development (NVIDIA)

```bash
# Pull the NVIDIA container (creates single .sif file)
ujust apptainer-pull-container-nvidia

# Run with GPU support (auto-detected)
ujust apptainer-run-container-nvidia

# Inside container
cd /workspace          # Your workspace is here
nvidia-smi            # Test GPU
python train.py       # Run your code
```

**Manual commands:**

```bash
# Pull container
apptainer pull docker://ghcr.io/atrawog/bazzite-ai-container-nvidia:latest

# Interactive shell with GPU
apptainer shell --nv --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container-nvidia_latest.sif

# Execute single command
apptainer exec --nv --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container-nvidia_latest.sif \
  python script.py
```

:::

:::{tab-item} CPU-Only Development

```bash
# Pull the base container
ujust apptainer-pull-container

# Run without GPU
ujust apptainer-run-container

# Inside container
cd /workspace          # Your workspace is here
python script.py      # Run your code
```

**Manual commands:**

```bash
# Pull container
apptainer pull docker://ghcr.io/atrawog/bazzite-ai-container:latest

# Interactive shell
apptainer shell --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container_latest.sif

# Execute single command
apptainer exec --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container_latest.sif \
  python script.py
```

:::

::::

**Advantages:**
- ✅ Single .sif file → Easy to share/archive for reproducibility
- ✅ No daemon required → Works on HPC clusters
- ✅ Native GPU via `--nv` → No nvidia-container-toolkit setup
- ✅ Standard in research → Used across academia
- ✅ Rootless by design → Secure by default

### Option B: VS Code Dev Containers

```{admonition} Best for
:class: tip

IDE integration, container-in-container development, full-featured environment
```

::::{tab-set}

:::{tab-item} GPU Development (NVIDIA)

```bash
# 1. Open repository in VS Code
cd /path/to/bazzite-ai
code .

# 2. Install Dev Containers extension (if not already installed)
# Press Ctrl+Shift+X, search for "Dev Containers", install

# 3. Reopen in container
# Press Ctrl+Shift+P, type "Reopen in Container", press Enter
```

This uses `.devcontainer/devcontainer.json` which configures the NVIDIA variant with GPU support.

```{note}
GPU is **automatically detected**! The devcontainer configuration:
- Works on bazzite-ai (with or without NVIDIA GPU)
- Auto-detects GPU availability and gracefully falls back to CPU-only mode
- Uses the latest pre-built image from GitHub Container Registry
```

:::

:::{tab-item} CPU-Only Development

```bash
# 1. Open repository in VS Code
cd /path/to/bazzite-ai
code .

# 2. Open command palette
# Press Ctrl+Shift+P

# 3. Select container configuration
# Type "Dev Containers: Open Container Configuration File"
# Select .devcontainer/devcontainer-base.json

# 4. Reopen in container
# Press Ctrl+Shift+P, type "Reopen in Container", press Enter
```

This uses `.devcontainer/devcontainer-base.json` which configures the base (CPU-only) variant.

:::

::::

### Option C: Standalone Container (Podman/Docker)

::::{tab-set}

:::{tab-item} GPU Development (NVIDIA)

```bash
# Pull pre-built image
just pull-container-nvidia

# Run with GPU
just run-container-nvidia

# Test CUDA
just test-cuda-container
```

:::

:::{tab-item} CPU-Only Development

```bash
# Pull pre-built image
just pull-container

# Run without GPU
just run-container
```

:::

::::

## Host Requirements

### For GPU Acceleration (NVIDIA)

```{danger}
**You must be running bazzite-ai (KDE only).**

Bazzite AI only supports KDE Plasma, not GNOME.
```

**Requirements:**

1. **Verify you're on bazzite-ai:**
   ```bash
   cat /usr/share/ublue-os/image-info.json | jq -r '."image-name"'
   # Should output: bazzite-ai
   ```

2. **nvidia-container-toolkit is pre-installed** on bazzite-ai

3. **Generate CDI configuration** (one-time setup):
   ```bash
   ujust setup-gpu-containers
   ```

4. **Verify GPU access:**
   ```bash
   podman run --rm --device nvidia.com/gpu=all \
     nvidia/cuda:12.6.3-base-fedora42 nvidia-smi
   ```

See {doc}`gpu-setup` for detailed setup instructions.

### For CPU-Only Development

```{tip}
No special requirements! Works on any bazzite-ai variant (including systems without NVIDIA GPUs).
```

## Justfile Commands

All commands support an optional `tag` parameter (default: `latest`).

### Base Container (CPU-Only)

```bash
# Pull latest from GHCR
just pull-container

# Pull specific tag
just pull-container stable
just pull-container 20251022

# Build from source
just build-container

# Force rebuild (no cache)
just rebuild-container

# Run standalone
just run-container

# Cleanup
just clean-container
```

### NVIDIA Container (GPU)

```bash
# Pull latest from GHCR
just pull-container-nvidia

# Pull specific tag
just pull-container-nvidia stable
just pull-container-nvidia 20251022

# Build from source (requires base container)
just build-container-nvidia

# Force rebuild (no cache)
just rebuild-container-nvidia

# Run with GPU
just run-container-nvidia

# Test CUDA
just test-cuda-container

# Cleanup
just clean-container-nvidia
```

## VS Code Usage

### GPU Development Setup

::::{dropdown} Step-by-step GPU setup
:open:

1. **Install Dev Containers Extension:**
   - Open VS Code
   - Press `Ctrl+Shift+X`
   - Search for "Dev Containers"
   - Install "Dev Containers" by Microsoft

2. **Configure GPU Access** (if using NVIDIA):
   ```bash
   # On host system (bazzite-ai)
   ujust setup-gpu-containers
   ```

3. **Open in Container:**
   - Open bazzite-ai repository in VS Code
   - Press `Ctrl+Shift+P`
   - Type "Dev Containers: Reopen in Container"
   - Press Enter (GPU auto-detected)

::::

### CPU-Only Development Setup

::::{dropdown} Step-by-step CPU-only setup

1. **Install Dev Containers Extension** (same as above)

2. **Open in Container:**
   - Open bazzite-ai repository in VS Code
   - Press `Ctrl+Shift+P`
   - Type "Dev Containers: Open Container Configuration File"
   - Select `.devcontainer/devcontainer-base.json`
   - Press `Ctrl+Shift+P` again
   - Type "Dev Containers: Reopen in Container"
   - Press Enter

::::

### Using the Container

Once inside the container:

```bash
# Test tools
git --version
python3 --version
node --version
code --version

# Test CUDA access (nvidia variant only)
nvidia-smi

# Your workspace is mounted at /workspace
cd /workspace
ls
```

### Getting Updates

```{tip}
The containers use the latest pre-built images from GitHub Container Registry.
```

To get the newest updates:

1. Press `Ctrl+Shift+P`
2. Type "Dev Containers: Rebuild Container"
3. Select "Rebuild Container"

This will pull the latest image with all updates and security patches.

## CUDA Verification (NVIDIA Variant Only)

### Inside Container

```bash
# Check CUDA toolkit
nvcc --version

# Check GPU access
nvidia-smi

# Test CUDA sample
cat > test.cu <<'EOF'
#include <stdio.h>
__global__ void hello() {
    printf("Hello from GPU!\n");
}
int main() {
    hello<<<1,1>>>();
    cudaDeviceSynchronize();
    return 0;
}
EOF

nvcc test.cu -o test
./test
```

### Python CUDA Test

```python
import torch
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA device count: {torch.cuda.device_count()}")
if torch.cuda.is_available():
    print(f"CUDA device name: {torch.cuda.get_device_name(0)}")
```

## Configuration

### Custom Container Settings

Edit `.devcontainer/devcontainer.json` (NVIDIA) or `.devcontainer/devcontainer-base.json` (base):

```json
{
  "customizations": {
    "vscode": {
      "settings": {
        "python.defaultInterpreterPath": "/usr/bin/python3",
        "terminal.integrated.defaultProfile.linux": "zsh"
      },
      "extensions": [
        "anthropic.claude-code",
        "ms-python.python",
        "your-favorite-extension"
      ]
    }
  }
}
```

### Mount Additional Directories

```json
{
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind",
    "source=${localEnv:HOME}/data,target=/data,type=bind"
  ]
}
```

### Environment Variables

```json
{
  "containerEnv": {
    "MY_VAR": "value",
    "CUDA_VISIBLE_DEVICES": "0"
  }
}
```

(troubleshooting)=
## Troubleshooting

### GPU Not Detected (NVIDIA Variant)

**Symptom:** `nvidia-smi` returns error

::::{dropdown} Solutions

1. Verify you're on bazzite-ai (KDE):
   ```bash
   cat /usr/share/ublue-os/image-info.json | jq -r '."image-name"'
   ```

2. Run CDI configuration:
   ```bash
   ujust setup-gpu-containers
   ```

3. Check CDI file exists:
   ```bash
   ls -la /etc/cdi/nvidia.yaml
   ```

4. Verify NVIDIA drivers on host:
   ```bash
   lsmod | grep nvidia
   ```

::::

### "nvidia.com/gpu" Device Not Found

**Symptom:** Container fails to start with GPU device error

::::{dropdown} Solutions

1. Regenerate CDI configuration:
   ```bash
   sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
   ```

2. Restart Podman:
   ```bash
   systemctl --user restart podman.socket
   ```

3. Try CPU-only mode temporarily:
   ```bash
   just run-container  # Use base container instead
   ```

::::

### SELinux Permission Denied

**Symptom:** Permission errors when accessing files

::::{dropdown} Solutions

1. Relabel workspace directory:
   ```bash
   chcon -R -t container_file_t ~/path/to/bazzite-ai
   ```

2. Or run with `:Z` flag (already in justfile commands):
   ```bash
   podman run -v $(pwd):/workspace:Z ...
   ```

::::

### Container Build Fails

**Symptom:** Build errors during `just build-container` or `just build-container-nvidia`

::::{dropdown} Solutions

1. Clear buildah cache:
   ```bash
   podman system reset --force
   ```

2. For base container, pull base image manually:
   ```bash
   podman pull fedora:42
   ```

3. For nvidia container, ensure base container exists:
   ```bash
   just build-container  # Build base first
   just build-container-nvidia  # Then build nvidia
   ```

4. Check network connectivity:
   ```bash
   ping packages.microsoft.com
   ```

::::

### VS Code Can't Connect

**Symptom:** VS Code fails to connect to container

::::{dropdown} Solutions

1. Rebuild container:
   - Press `Ctrl+Shift+P`
   - "Dev Containers: Rebuild Container"

2. Check container is running:
   ```bash
   podman ps
   ```

3. Try pulling fresh image:
   ```bash
   just pull-container        # For base
   just pull-container-nvidia # For nvidia
   ```

::::

## Performance Tips

### GPU Optimization (NVIDIA Variant)

```bash
# Inside container, set CUDA visible devices
export CUDA_VISIBLE_DEVICES=0

# For multi-GPU systems, specify which GPU
export CUDA_VISIBLE_DEVICES=0,1
```

### Memory Management

```bash
# Monitor GPU memory (nvidia variant)
watch -n 1 nvidia-smi

# Clear CUDA cache (Python)
python3 -c "import torch; torch.cuda.empty_cache()"
```

### Build Cache

Speed up rebuilds by preserving package cache:

```json
// Add to devcontainer.json:
"mounts": [
  "source=container-cache,target=/var/cache/dnf5,type=volume"
]
```

## Advanced Usage

### Container-in-Container

Docker socket is mounted by default:

```bash
# Inside container
docker ps
docker build -t myimage .
podman ps
```

### Jupyter Notebooks with CUDA (NVIDIA Variant)

```bash
pip install jupyter torch

# Start Jupyter with GPU
jupyter notebook --ip=0.0.0.0 --allow-root
```

Access at `http://localhost:8888`

### Remote Development

```bash
# On remote bazzite-ai machine
just run-container-nvidia  # For GPU
# OR
just run-container         # For CPU-only

# From local machine
ssh -L 8888:localhost:8888 user@remote-host
```

## Security Considerations

### Safe for skip-permissions

```{tip}
The containers provide isolation, making it safe to run:

    claude --dangerously-skip-permissions

Changes are contained within the container and don't affect the host system.
```

### Non-root User

The containers run as `devuser` (non-root) with sudo access:

```bash
# Regular user
whoami  # devuser

# Sudo available when needed
sudo dnf install package
```

### Network Isolation

For enhanced security:

```json
{
  "runArgs": [
    "--network=none"  // No network access
  ]
}
```

## Related Documentation

```{seealso}
- {doc}`gpu-setup` - GPU setup on host system
- {doc}`../../developer-guide/building/iso-build` - Building bazzite-ai ISO
- {doc}`../../developer-guide/testing/container-testing` - Container testing guide
```

## Getting Help

- Check [GitHub Issues](https://github.com/atrawog/bazzite-ai/issues)
- Review {ref}`troubleshooting` section above
- Verify host setup in {doc}`gpu-setup`
