# Bazzite AI Container Guide

## Overview

Bazzite AI provides two development container variants for isolated development work:

1. **bazzite-ai-container** - Base CPU-only development container
2. **bazzite-ai-container-nvidia** - GPU-accelerated container (builds on base, adds cuDNN/TensorRT)

Both containers include all development tools from bazzite-ai without the OS overhead, providing safe isolated environments for development.

### Key Features

- **Dual Architecture**: Separate base (CPU) and NVIDIA (GPU) containers for optimal efficiency
- **All Dev Tools**: VS Code, Docker, Python, Node.js, BPF tools, Android tools, and more
- **Safe Isolation**: Perfect for running Claude Code with `--dangerously-skip-permissions` safely
- **Container-in-Container**: Docker socket mount for building containers inside container
- **Pre-built Images**: Auto-built via GitHub Actions, pull from GHCR
- **VS Code Native**: Full VS Code Dev Containers support
- **GPU Support**: Full CUDA acceleration via NVIDIA Container Toolkit (nvidia variant only)

### Use Cases

1. **Claude Code Development**: Safe isolated environment for AI-assisted coding
2. **CUDA/GPU Development**: ML/AI workloads with full GPU acceleration (nvidia variant)
3. **Multi-platform Development**: Consistent environment across machines
4. **Experimentation**: Test changes without affecting host system
5. **HPC/Research**: Reproducible environments via Apptainer .sif files

## Container Variants

### bazzite-ai-container (Base)

**CPU-only development container** - Clean base image with no NVIDIA/CUDA dependencies.

**Purpose:**
- CPU-only development and testing
- Lightweight for systems without GPUs
- Base layer for nvidia variant

**Key Features:**
- Clean separation: No CUDA/NVIDIA references
- Smaller size: No ML libraries overhead
- Fedora 42 base with all development tools

**Image:** `ghcr.io/atrawog/bazzite-ai-container`

### bazzite-ai-container-nvidia (NVIDIA)

**GPU-accelerated development container** - Builds on base, adds cuDNN and TensorRT.

**Purpose:**
- CUDA-accelerated AI/ML workflows
- GPU development and testing
- Includes optimized ML libraries

**Key Features:**
- Built on base: Layered architecture for efficient builds
- ML Libraries: cuDNN and TensorRT pre-installed
- Host passthrough: Uses host CUDA runtime via nvidia-container-toolkit

**Image:** `ghcr.io/atrawog/bazzite-ai-container-nvidia`

**Host Requirements:**
1. Must use **bazzite-ai-nvidia** (KDE variant only)
2. nvidia-container-toolkit (pre-installed)
3. CDI config via `ujust setup-gpu-containers`

See [HOST-SETUP-GPU.md](HOST-SETUP-GPU.md) for detailed GPU setup.

## Quick Start: Choose Your Platform

### Option A: Apptainer (Recommended for HPC/Research)

**Best for**: Scientific computing, HPC clusters, reproducible research

#### GPU Development (NVIDIA)

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

#### CPU-Only Development

```bash
# Pull the base container
ujust apptainer-pull-container

# Run without GPU
ujust apptainer-run-container

# Inside container
cd /workspace          # Your workspace is here
python script.py      # Run your code
```

**Advantages:**
- Single .sif file → Easy to share/archive for reproducibility
- No daemon required → Works on HPC clusters
- Native GPU via `--nv` → No nvidia-container-toolkit setup
- Standard in research → Used across academia
- Rootless by design → Secure by default

**Manual Commands:**

```bash
# GPU Development (NVIDIA)
apptainer pull docker://ghcr.io/atrawog/bazzite-ai-container-nvidia:latest
apptainer shell --nv --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container-nvidia_latest.sif

# CPU-Only Development
apptainer pull docker://ghcr.io/atrawog/bazzite-ai-container:latest
apptainer shell --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container_latest.sif

# Execute single command (NVIDIA with GPU)
apptainer exec --nv --writable-tmpfs \
  --bind $(pwd):/workspace \
  bazzite-ai-container-nvidia_latest.sif \
  python script.py
```

### Option B: VS Code Dev Containers

**Best for**: IDE integration, container-in-container development

#### GPU Development (NVIDIA)

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

**GPU is automatically detected!** The devcontainer configuration:
- Works on both bazzite-ai-nvidia (with GPU) and bazzite-ai (without GPU)
- Auto-detects GPU availability and gracefully falls back to CPU-only mode
- Uses the latest pre-built image from GitHub Container Registry

#### CPU-Only Development

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

### Option C: Standalone Container (Podman/Docker)

#### GPU Development (NVIDIA)

```bash
# Pull pre-built image
just pull-container-nvidia

# Run with GPU
just run-container-nvidia

# Test CUDA
just test-cuda-container
```

#### CPU-Only Development

```bash
# Pull pre-built image
just pull-container

# Run without GPU
just run-container
```

## Host Requirements

### For GPU Acceleration (NVIDIA)

**You must be running bazzite-ai-nvidia (KDE variant).**

⚠️ **Important**: bazzite-ai only supports KDE Plasma variants, not GNOME.

1. **Verify you're on bazzite-ai-nvidia**:
   ```bash
   cat /usr/share/ublue-os/image-info.json | jq -r '.\"image-name\"'
   # Should output: bazzite-ai-nvidia
   ```

2. **nvidia-container-toolkit is pre-installed** on bazzite-ai-nvidia

3. **Generate CDI configuration** (one-time setup):
   ```bash
   ujust setup-gpu-containers
   ```

4. **Verify GPU access**:
   ```bash
   podman run --rm --device nvidia.com/gpu=all \
     nvidia/cuda:12.6.3-base-fedora42 nvidia-smi
   ```

See [HOST-SETUP-GPU.md](HOST-SETUP-GPU.md) for detailed setup instructions.

### For CPU-Only Development

No special requirements. Works on any bazzite-ai variant (including non-NVIDIA).

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

1. **Install Dev Containers Extension**:
   - Open VS Code
   - Press `Ctrl+Shift+X`
   - Search for "Dev Containers"
   - Install "Dev Containers" by Microsoft

2. **Configure GPU Access** (if using NVIDIA):
   ```bash
   # On host system (bazzite-ai-nvidia)
   ujust setup-gpu-containers
   ```

3. **Open in Container**:
   - Open bazzite-ai repository in VS Code
   - Press `Ctrl+Shift+P`
   - Type "Dev Containers: Reopen in Container"
   - Press Enter (GPU auto-detected)

### CPU-Only Development Setup

1. **Install Dev Containers Extension** (same as above)

2. **Open in Container**:
   - Open bazzite-ai repository in VS Code
   - Press `Ctrl+Shift+P`
   - Type "Dev Containers: Open Container Configuration File"
   - Select `.devcontainer/devcontainer-base.json`
   - Press `Ctrl+Shift+P` again
   - Type "Dev Containers: Reopen in Container"
   - Press Enter

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

The containers use the latest pre-built images from GitHub Container Registry. To get the newest updates:

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

## Troubleshooting

### GPU Not Detected (NVIDIA Variant)

**Symptom**: `nvidia-smi` returns error

**Solutions**:
1. Verify you're on bazzite-ai-nvidia (KDE):
   ```bash
   cat /usr/share/ublue-os/image-info.json | jq -r '.\"image-name\"'
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

### "nvidia.com/gpu" Device Not Found

**Symptom**: Container fails to start with GPU device error

**Solutions**:
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

### SELinux Permission Denied

**Symptom**: Permission errors when accessing files

**Solutions**:
1. Relabel workspace directory:
   ```bash
   chcon -R -t container_file_t ~/path/to/bazzite-ai
   ```

2. Or run with `:Z` flag (already in justfile commands):
   ```bash
   podman run -v $(pwd):/workspace:Z ...
   ```

### Container Build Fails

**Symptom**: Build errors during `just build-container` or `just build-container-nvidia`

**Solutions**:
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

### VS Code Can't Connect

**Symptom**: VS Code fails to connect to container

**Solutions**:
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

```bash
# Speed up rebuilds by preserving package cache
# Add to devcontainer.json:
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
# On remote bazzite-ai-nvidia machine
just run-container-nvidia  # For GPU
# OR
just run-container         # For CPU-only

# From local machine
ssh -L 8888:localhost:8888 user@remote-host
```

## Security Considerations

### Safe for skip-permissions

The containers provide isolation, making it safe to run:

```bash
claude --dangerously-skip-permissions
```

Changes are contained within the container and don't affect the host system.

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

- [HOST-SETUP-GPU.md](HOST-SETUP-GPU.md) - GPU setup on host system
- [ISO-BUILD.md](ISO-BUILD.md) - Building bazzite-ai-nvidia
- [CLAUDE.md](../CLAUDE.md) - Full repository documentation

## Getting Help

- Check [GitHub Issues](https://github.com/atrawog/bazzite-ai/issues)
- Review [troubleshooting section](#troubleshooting) above
- Verify host setup in [HOST-SETUP-GPU.md](HOST-SETUP-GPU.md)
