# GPU Setup for Containers

Bazzite AI supports two container platforms with GPU access:

## Apptainer (Native GPU Support)

**No setup required!** Apptainer has built-in NVIDIA GPU support.

### Quick Start

```bash
# Pull bazzite-ai-devcontainer
ujust apptainer-pull-devcontainer

# Run with GPU (auto-detected)
ujust apptainer-run-devcontainer

# Verify GPU access
apptainer exec --nv ~/bazzite-ai-devcontainer_latest.sif nvidia-smi
```

### Manual Usage

```bash
# Any container with GPU
apptainer run --nv my-container.sif

# Specific GPU selection
APPTAINERENV_CUDA_VISIBLE_DEVICES=0 apptainer run --nv container.sif

# Multiple GPUs
APPTAINERENV_CUDA_VISIBLE_DEVICES=0,1 apptainer run --nv container.sif
```

### How It Works

Apptainer's `--nv` flag:
- Binds `/dev/nvidia*` devices into container
- Mounts CUDA libraries from host
- Configures LD_LIBRARY_PATH automatically
- No daemon or toolkit configuration needed

## Podman/Docker (Requires CDI Setup)

For Podman/Docker GPU access, follow the setup below:

### Prerequisites

**You must be running bazzite-ai (KDE only).**

⚠️ **Important**: Bazzite AI only supports KDE Plasma, not GNOME.

### Verify Your Variant

```bash
# Check which variant you're running
cat /usr/share/ublue-os/image-info.json | jq -r '."image-name"'

# Should output:
# - bazzite-ai  (KDE with NVIDIA open driver support - works on all GPUs)
```

The unified bazzite-ai image includes nvidia-container-toolkit pre-installed for GPU container support.

### Podman/Docker Setup Steps

#### Step 1: Verify NVIDIA Drivers

On bazzite-ai, NVIDIA open drivers are pre-installed. Verify they're loaded:

```bash
# Check NVIDIA kernel modules
lsmod | grep nvidia

# Should show modules like:
# nvidia_drm
# nvidia_modeset
# nvidia
# nvidia_uvm

# Test GPU access on host
nvidia-smi
```

If `nvidia-smi` doesn't work, you may need to reboot after installing bazzite-ai.

#### Step 2: Verify nvidia-container-toolkit Installation

The toolkit is pre-installed on bazzite-ai:

```bash
# Check if installed
rpm -q nvidia-container-toolkit

# Check version (should be 1.17.4 or newer on Fedora 42)
nvidia-container-toolkit --version

# Verify nvidia-ctk is available
which nvidia-ctk
```

If not installed (shouldn't happen on recent builds), reinstall bazzite-ai or build a new image.

#### Step 3: Generate CDI Configuration

**This is a one-time setup** that enables GPU passthrough to containers via CDI (Container Device Interface).

#### Easy Method (Recommended)

```bash
# Use the ujust command
ujust setup-gpu-containers
```

This will:
1. Check that nvidia-container-toolkit is installed
2. Warn if no NVIDIA GPU is detected
3. Generate `/etc/cdi/nvidia.yaml` configuration
4. Provide next steps

#### Manual Method

```bash
# Generate CDI specification
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# Verify it was created
ls -lh /etc/cdi/nvidia.yaml
```

The CDI file tells Podman how to expose GPU devices to containers.

#### Step 4: Verify GPU Container Access

Test that containers can access your GPU:

```bash
# Test with NVIDIA CUDA base image
podman run --rm --device nvidia.com/gpu=all \
  nvidia/cuda:12.6.3-base-fedora42 nvidia-smi

# You should see your GPU listed
# Example output:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 550.54.14    Driver Version: 550.54.14    CUDA Version: 12.4    |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# |   0  NVIDIA GeForce RTX 3080  Off | 00000000:01:00.0 On |                  N/A |
# +-------------------------------+----------------------+----------------------+
```

#### Step 5: Test with Devcontainer

```bash
cd /path/to/bazzite-ai

# Pull the devcontainer
just pull-devcontainer

# Test CUDA access
just test-cuda-devcontainer

# You should see nvidia-smi output showing your GPU
```

## Troubleshooting

### nvidia-container-toolkit Not Found

**Symptom**: `ujust setup-gpu-containers` says nvidia-container-toolkit not found

**Cause**: Running an old build before nvidia-container-toolkit was included

**Solutions**:

1. Verify you're on bazzite-ai:
   ```bash
   cat /usr/share/ublue-os/image-info.json | jq -r '."image-name"'
   ```

2. Update to latest version:
   ```bash
   rpm-ostree rebase ostree-image-signed:docker://ghcr.io/atrawog/bazzite-ai:stable
   systemctl reboot
   ```

3. Check if packages are staging:
   ```bash
   rpm-ostree status
   # Look for pending deployment
   ```

### GPU Not Detected on Host

**Symptom**: `nvidia-smi` returns "No devices were found"

**Solutions**:

1. Reboot after installing bazzite-ai:
   ```bash
   systemctl reboot
   ```

2. Check if card is detected by system:
   ```bash
   lspci | grep -i nvidia
   # Should show your NVIDIA card
   ```

3. Verify you have nvidia variant (not base bazzite-ai):
   ```bash
   rpm -qa | grep nvidia
   # Should show many nvidia packages
   ```

### CDI Configuration Missing

**Symptom**: Container fails with "nvidia.com/gpu: device not found"

**Solutions**:

1. Regenerate CDI config:
   ```bash
   sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
   ```

2. Check file exists and is readable:
   ```bash
   ls -lh /etc/cdi/nvidia.yaml
   cat /etc/cdi/nvidia.yaml | head -20
   ```

3. Restart Podman service:
   ```bash
   systemctl --user restart podman.socket
   ```

### SELinux Denials

**Symptom**: "Permission denied" errors accessing GPU

**Solutions**:

1. Check SELinux is enabled:
   ```bash
   getenforce
   # Should show: Enforcing
   ```

2. The devcontainer uses `--security-opt label=disable` to bypass SELinux restrictions for GPU access. This is normal and safe for development containers.

3. If you need SELinux enabled, install the NVIDIA container SELinux policy (advanced):
   ```bash
   # This may require building custom policy
   # See: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#selinux
   ```

### Containers Can't See GPU But Host Can

**Symptom**: `nvidia-smi` works on host, fails in container

**Solutions**:

1. Verify CDI configuration:
   ```bash
   nvidia-ctk cdi list
   # Should show available GPU devices
   ```

2. Check Podman version:
   ```bash
   podman --version
   # Should be 4.0+ with CDI support
   ```

3. Try with explicit device ID:
   ```bash
   podman run --rm --device nvidia.com/gpu=0 \
     nvidia/cuda:12.6.3-base-fedora42 nvidia-smi
   ```

4. Check if running rootless Podman:
   ```bash
   # CDI should work with rootless Podman
   # If issues, try rootful:
   sudo podman run --rm --device nvidia.com/gpu=all \
     nvidia/cuda:12.6.3-base-fedora42 nvidia-smi
   ```

### Old CUDA Version in Container

**Symptom**: Container shows different CUDA version than expected

**Note**: This is normal! The CUDA version shown by `nvidia-smi` in the container reflects the **host driver** version, not the container's CUDA toolkit version.

```bash
# Check host driver version
nvidia-smi | grep "Driver Version"

# Check container CUDA toolkit version
podman run --rm bazzite-ai-devcontainer:latest nvcc --version
```

They can be different - this is expected and usually not a problem.

## Advanced Configuration

### Multiple GPUs

If you have multiple GPUs, you can select specific ones:

```bash
# Use only GPU 0
export CUDA_VISIBLE_DEVICES=0
just run-devcontainer

# Or in devcontainer.json:
{
  "containerEnv": {
    "CUDA_VISIBLE_DEVICES": "0,1"
  }
}
```

### Custom CDI Configuration

Edit `/etc/cdi/nvidia.yaml` to customize GPU exposure:

```yaml
# View current config
cat /etc/cdi/nvidia.yaml

# After editing, no need to restart - CDI is read on container start
```

### Monitor GPU Usage

```bash
# Real-time monitoring
watch -n 1 nvidia-smi

# Or use nvidia-smi in daemon mode
nvidia-smi dmon
```

## Verification Checklist

Use this checklist to verify everything is working:

- [ ] Running bazzite-ai (KDE)
- [ ] `nvidia-smi` works on host
- [ ] `nvidia-container-toolkit` is installed
- [ ] `/etc/cdi/nvidia.yaml` exists
- [ ] Test container can see GPU: `podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.6.3-base-fedora42 nvidia-smi`
- [ ] `just test-cuda-devcontainer` shows GPU
- [ ] VS Code devcontainer can access GPU

## Related Documentation

- [CONTAINER.md](CONTAINER.md) - Container usage guide
- [ISO-BUILD.md](ISO-BUILD.md) - Building bazzite-ai ISO
- [CLAUDE.md](../CLAUDE.md) - Full repository documentation

## External Resources

- [NVIDIA Container Toolkit Documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
- [Podman CDI Documentation](https://podman-desktop.io/docs/podman/gpu)
- [Fedora NVIDIA Guide](https://rpmfusion.org/Howto/NVIDIA)

## Getting Help

If you're still having issues:

1. Verify all checklist items above
2. Check [GitHub Issues](https://github.com/atrawog/bazzite-ai/issues)
3. Provide this information when asking for help:
   ```bash
   # System information
   cat /usr/share/ublue-os/image-info.json
   rpm -q nvidia-container-toolkit
   nvidia-smi
   ls -lh /etc/cdi/nvidia.yaml
   podman --version
   getenforce
   ```
