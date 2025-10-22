# Bazzite AI Devcontainer Guide

## Overview

**bazzite-ai-devcontainer** is a CUDA-enabled development container that provides a safe, isolated environment for development work. It includes all the development tools from bazzite-ai-nvidia (KDE variant) without the OS overhead.

### Key Features

- **CUDA Support**: Full GPU acceleration via NVIDIA Container Toolkit
- **All Dev Tools**: VS Code, Docker, Python, Node.js, BPF tools, Android tools, and more
- **Safe Isolation**: Perfect for running Claude Code with `--dangerously-skip-permissions` safely
- **Container-in-Container**: Docker socket mount for building containers inside devcontainer
- **Pre-built Images**: Auto-built via GitHub Actions, pull from GHCR
- **VS Code Native**: Full VS Code Dev Containers support

### Use Cases

1. **Claude Code Development**: Safe isolated environment for AI-assisted coding
2. **CUDA/GPU Development**: ML/AI workloads with full GPU acceleration
3. **Multi-platform Development**: Consistent environment across machines
4. **Experimentation**: Test changes without affecting host system

## Quick Start (3 Steps)

### Option A: VS Code (Recommended)

```bash
# 1. Open repository in VS Code
cd /path/to/bazzite-ai
code .

# 2. Install Dev Containers extension (if not already installed)
# Press Ctrl+Shift+X, search for "Dev Containers", install

# 3. Reopen in container
# Press Ctrl+Shift+P, type "Reopen in Container", press Enter
```

GPU access is automatically configured!

### Option B: Standalone Container

```bash
# Pull pre-built image
just pull-devcontainer

# Run with GPU
just run-devcontainer

# Or run without GPU (CPU only)
just run-devcontainer-no-gpu
```

## Host Requirements

### For GPU Acceleration (NVIDIA)

**You must be running bazzite-ai-nvidia (KDE variant).**

⚠️ **Important**: bazzite-ai only supports KDE Plasma variants, not GNOME.

1. **Verify you're on bazzite-ai-nvidia**:
   ```bash
   cat /usr/share/ublue-os/image-info.json | jq -r '."image-name"'
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

## VS Code Usage

### First Time Setup

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
   - Select "Bazzite AI Devcontainer (CUDA)"

### Using the Devcontainer

Once inside the container:

```bash
# Test CUDA access
nvidia-smi

# Your workspace is mounted at /workspace
cd /workspace
ls

# Claude Code is available
claude --version

# All dev tools are installed
git --version
python3 --version
node --version
code --version
```

### Switching Configurations

Two configurations are available:

- **devcontainer.json**: GPU-enabled (default)
- **devcontainer-no-gpu.json**: CPU-only

To switch:
1. Press `Ctrl+Shift+P`
2. Type "Dev Containers: Open Container Configuration File"
3. Select the desired configuration
4. Rebuild container

## Justfile Commands

All commands support an optional `tag` parameter (default: `latest`).

### Pull Pre-built Image

```bash
# Pull latest from GHCR
just pull-devcontainer

# Pull specific tag
just pull-devcontainer stable
just pull-devcontainer 20251022
```

### Build Locally

```bash
# Build from source
just build-devcontainer

# Force rebuild (no cache)
just rebuild-devcontainer

# Build specific tag
just build-devcontainer my-custom-tag
```

### Run Standalone

```bash
# Run with GPU
just run-devcontainer

# Run without GPU
just run-devcontainer-no-gpu

# Specific tag
just run-devcontainer stable
```

### Test CUDA

```bash
# Test GPU access
just test-cuda-devcontainer

# Should display NVIDIA GPU information
```

### Cleanup

```bash
# Remove devcontainer images
just clean-devcontainer
```

## CUDA Verification

### Inside Devcontainer

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

### Custom Devcontainer Settings

Edit `.devcontainer/devcontainer.json`:

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

### GPU Not Detected

**Symptom**: `nvidia-smi` returns error

**Solutions**:
1. Verify you're on bazzite-ai-nvidia (KDE):
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
   just run-devcontainer-no-gpu
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

**Symptom**: Build errors during `just build-devcontainer`

**Solutions**:
1. Clear buildah cache:
   ```bash
   podman system reset --force
   ```

2. Pull base image manually:
   ```bash
   podman pull nvidia/cuda:12.6.3-devel-fedora42
   ```

3. Check network connectivity:
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
   just pull-devcontainer
   ```

## Performance Tips

### GPU Optimization

```bash
# Inside container, set CUDA visible devices
export CUDA_VISIBLE_DEVICES=0

# For multi-GPU systems, specify which GPU
export CUDA_VISIBLE_DEVICES=0,1
```

### Memory Management

```bash
# Monitor GPU memory
watch -n 1 nvidia-smi

# Clear CUDA cache (Python)
python3 -c "import torch; torch.cuda.empty_cache()"
```

### Build Cache

```bash
# Speed up rebuilds by preserving package cache
# Add to devcontainer.json:
"mounts": [
  "source=devcontainer-cache,target=/var/cache/dnf5,type=volume"
]
```

## Advanced Usage

### Container-in-Container

Docker socket is mounted by default:

```bash
# Inside devcontainer
docker ps
docker build -t myimage .
podman ps
```

### Jupyter Notebooks with CUDA

```bash
pip install jupyter torch

# Start Jupyter with GPU
jupyter notebook --ip=0.0.0.0 --allow-root
```

Access at `http://localhost:8888`

### Remote Development

```bash
# On remote bazzite-ai-nvidia machine
just run-devcontainer

# From local machine
ssh -L 8888:localhost:8888 user@remote-host
```

## Security Considerations

### Safe for skip-permissions

The devcontainer provides isolation, making it safe to run:

```bash
claude --dangerously-skip-permissions
```

Changes are contained within the container and don't affect the host system.

### Non-root User

The devcontainer runs as `devuser` (non-root) with sudo access:

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
