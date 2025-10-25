---
title: Manual Testing Guide
---

# Manual Container Testing Guide

Quick reference for manually testing devcontainers-CLI and bazzite-ai containers.

## Quick Start: Test Everything in ~30 Minutes

### Phase 1: devcontainers-CLI Verification (~5 min)

```bash
# 1. Check installation
devcontainer --version
# Expected: 0.80.1 or newer

# 2. Verify PATH
which devcontainer
# Expected: ~/.npm-global/bin/devcontainer

# 3. Test help command
devcontainer --help | head -20

# 4. Verify configs exist
ls -l .devcontainer/
# Should see: devcontainer.json and devcontainer-base.json

# 5. Validate JSON syntax
jq empty .devcontainer/devcontainer.json && echo "✓ NVIDIA config valid"
jq empty .devcontainer/devcontainer-base.json && echo "✓ Base config valid"

# 6. Check image references
jq '.image' .devcontainer/devcontainer.json
# Expected: "ghcr.io/atrawog/bazzite-ai-container-nvidia:latest"

jq '.image' .devcontainer/devcontainer-base.json
# Expected: "ghcr.io/atrawog/bazzite-ai-container:latest"
```

```{admonition} Success Criteria
:class: tip

✓ devcontainers-CLI is functional if all commands succeed
```

### Phase 2: Apptainer Base Container (~10 min)

```bash
# 1. Check Apptainer
apptainer version
# Expected: apptainer version X.X.X

# 2. Show Apptainer info
ujust apptainer-info

# 3. Pull base container (~2GB, takes 5-10 min)
ujust apptainer-pull-container

# 4. Verify file created
ls -lh ~/bazzite-ai-container_latest.sif
du -h ~/bazzite-ai-container_latest.sif
# Expected: ~2GB file

# 5. Test interactive shell
ujust apptainer-run-container
# Inside container, run:
whoami                    # Your username
pwd                       # /workspace
python3 --version         # Python 3.x
node --version            # v2x.x.x
git --version             # git version X.X.X
exit                      # Exit container

# 6. Test command execution
ujust apptainer-exec-container "echo 'Test successful'"
ujust apptainer-exec-container "python3 --version"
```

```{admonition} Success Criteria
:class: tip

✓ Base container is functional if all tests pass
```

### Phase 3: Apptainer NVIDIA Container (~15 min)

```bash
# 1. Pull NVIDIA container (~4GB, takes 10-15 min)
ujust apptainer-pull-container-nvidia

# 2. Verify file created
ls -lh ~/bazzite-ai-container-nvidia_latest.sif
du -h ~/bazzite-ai-container-nvidia_latest.sif
# Expected: ~3-4GB file

# 3. Test interactive shell
ujust apptainer-run-container-nvidia
# Inside container, run:
whoami                    # Your username
python3 --version         # Python 3.x
nvidia-smi 2>&1 || echo "No GPU (expected)"  # GPU check

# Check for CUDA libraries
find /usr -name "libcudnn*" 2>/dev/null | head -3
find /usr -name "libnvinfer*" 2>/dev/null | head -3
# Should see library files

exit                      # Exit container

# 4. Test command execution
ujust apptainer-exec-container-nvidia "python3 -c 'import sys; print(sys.version)'"
ujust apptainer-exec-container-nvidia "which python3 node npm git"

# 5. Test workspace binding
cd /var/home/atrawog/Repo/bazzite-ai/bazzite-ai
ujust apptainer-exec-container-nvidia "ls -la /workspace"
# Should see repository files
```

```{admonition} Success Criteria
:class: tip

✓ NVIDIA container is functional if all tests pass
```

## Detailed Testing

### Test devcontainer Build (Optional, ~30 min)

::::{dropdown} Build both configurations

```bash
# Build base config
devcontainer build \
  --workspace-folder . \
  --config .devcontainer/devcontainer-base.json \
  --image-name test-base

# Verify image created
podman images | grep test-base

# Build NVIDIA config
devcontainer build \
  --workspace-folder . \
  --config .devcontainer/devcontainer.json \
  --image-name test-nvidia

# Verify image created
podman images | grep test-nvidia
```

::::

### Test Podman/Docker (Development, ~15 min)

::::{dropdown} Test with Podman directly

```bash
# Pull containers via Podman
just pull-container
just pull-container-nvidia

# Verify images
podman images | grep bazzite-ai-container

# Run base container
just run-container
# Inside container:
python3 --version
node --version
exit

# Run NVIDIA container
just run-container-nvidia
# Inside container:
nvidia-smi 2>&1 || echo "No GPU"
python3 --version
exit

# Test CUDA (if GPU available)
just test-cuda-container
```

::::

## Testing Checklist

Use this checklist for manual testing:

### devcontainers-CLI

- [ ] `devcontainer --version` shows correct version
- [ ] `which devcontainer` returns valid path
- [ ] Both devcontainer configs exist and are valid JSON
- [ ] Image references point to GHCR correctly
- [ ] (Optional) Builds complete successfully

### Apptainer Base Container

- [ ] `apptainer version` works
- [ ] `ujust apptainer-pull-container` downloads ~2GB .sif file
- [ ] Interactive shell works with `ujust apptainer-run-container`
- [ ] Python, Node.js, Git are available in container
- [ ] Workspace is mounted correctly at `/workspace`
- [ ] Command execution works via `ujust apptainer-exec-container`

### Apptainer NVIDIA Container

- [ ] `ujust apptainer-pull-container-nvidia` downloads ~3-4GB .sif file
- [ ] Interactive shell works with GPU flag
- [ ] CUDA libraries (cuDNN, TensorRT) are present
- [ ] Python and development tools available
- [ ] Workspace mounting works
- [ ] Command execution works with GPU support

### Podman/Docker (Optional)

- [ ] Images pull successfully
- [ ] Containers run interactively
- [ ] GPU passthrough works (if applicable)
- [ ] Development tools available

## Quick Commands Reference

### devcontainers-CLI

```bash
devcontainer --version
devcontainer --help
devcontainer build --workspace-folder . --config .devcontainer/devcontainer-base.json
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . <command>
```

### Apptainer

```bash
ujust apptainer-info
ujust apptainer-pull-container
ujust apptainer-run-container
ujust apptainer-exec-container "<command>"
ujust apptainer-pull-container-nvidia
ujust apptainer-run-container-nvidia
ujust apptainer-exec-container-nvidia "<command>"
```

### Podman/Docker

```bash
just pull-container
just pull-container-nvidia
just run-container
just run-container-nvidia
just test-cuda-container
```

## Troubleshooting

### Container Not Found

```bash
# Check if image exists
podman images | grep bazzite-ai-container

# Pull manually
podman pull ghcr.io/atrawog/bazzite-ai-container:latest
```

### Permission Denied

```bash
# Check SELinux context
ls -Z ~/bazzite-ai-container_latest.sif

# Relabel if needed
chcon -t container_file_t ~/bazzite-ai-container_latest.sif
```

### Apptainer Command Not Found

```bash
# Check if installed
which apptainer

# Install if needed
sudo dnf install apptainer
```

## Related Documentation

```{seealso}
- {doc}`container-testing` - Automated testing scripts
- {doc}`index` - Testing overview
- {doc}`../../user-guide/containers/usage` - Container usage guide
```
