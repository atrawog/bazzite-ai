# Manual Container Testing Guide

Quick reference for manually testing devcontainers-CLI and bazzite-ai containers using ujust commands.

## Quick Start: Test Everything in ~30 Minutes

### Phase 1: devcontainers-CLI Verification (~5 min)

```bash
# 1. Check installation
devcontainer --version
# Expected: 0.80.1

# 2. Verify PATH
which devcontainer
# Expected: /home/atrawog/.npm-global/bin/devcontainer or similar

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

**✓ devcontainers-CLI is functional if all commands succeed**

---

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
ujust apptainer-exec-container-nvidia "echo 'Test successful'"
ujust apptainer-exec-container-nvidia "python3 --version"
```

**✓ Base container is functional if all tests pass**

---

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

**✓ NVIDIA container is functional if all tests pass**

---

## Detailed Testing

### Test devcontainer Build (Optional, ~30 min)

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

### Test Podman/Docker (Development, ~15 min)

```bash
# Pull containers via Podman
just pull-container
just pull-container-nvidia

# Verify images
podman images | grep bazzite-ai-container

# Run base container
just run-container
# Inside: test tools, then exit

# Run NVIDIA container
just run-container-nvidia
# Inside: test tools, then exit

# Test CUDA
just test-cuda-container
# Will show no GPU (expected without hardware)

# Clean up
just clean-container
```

---

## Verification Checklist

### devcontainers-CLI ✓
- [ ] `devcontainer --version` shows 0.80.1
- [ ] `devcontainer --help` works
- [ ] Both .devcontainer configs are valid JSON
- [ ] Image references point to ghcr.io/atrawog/*
- [ ] (Optional) Builds complete successfully

### Apptainer Base Container ✓
- [ ] `ujust apptainer-info` works
- [ ] `ujust apptainer-pull-container` downloads ~2GB .sif
- [ ] `~/bazzite-ai-container_latest.sif` exists
- [ ] `ujust apptainer-run-container` opens interactive shell
- [ ] Python, Node.js, Git available in container
- [ ] `ujust apptainer-exec-container-nvidia CMD` works

### Apptainer NVIDIA Container ✓
- [ ] `ujust apptainer-pull-container-nvidia` downloads ~4GB .sif
- [ ] `~/bazzite-ai-container-nvidia_latest.sif` exists
- [ ] `ujust apptainer-run-container-nvidia` opens interactive shell
- [ ] Python, Node.js, Git available in container
- [ ] cuDNN libraries found: `find /usr -name "libcudnn*"`
- [ ] TensorRT libraries found: `find /usr -name "libnvinfer*"`
- [ ] Workspace binding works (can see /workspace)

---

## Common Issues & Solutions

### devcontainer command not found
```bash
# Reinstall
ujust install-devcontainers-cli

# Check PATH
echo $PATH | grep npm-global
source ~/.bashrc
```

### Container pulls timeout
```bash
# Check network
ping -c 3 ghcr.io

# Check disk space (need ~7GB free)
df -h ~

# Try manual pull
apptainer pull docker://ghcr.io/atrawog/bazzite-ai-container:latest
```

### ujust command not found
```bash
# Check if available
which ujust

# If not, use just instead
just --help
```

### Permission denied on .sif files
```bash
# Check ownership
ls -l ~/bazzite-ai-container*.sif

# Fix if needed
chmod 644 ~/bazzite-ai-container*.sif
```

---

## Quick Tests (One-Liners)

### Verify Everything Quickly
```bash
# devcontainers-cli
devcontainer --version && echo "✓ CLI installed"

# Apptainer
apptainer version && echo "✓ Apptainer installed"

# ujust commands
ujust --list | grep apptainer && echo "✓ ujust apptainer commands available"

# Container files
ls -lh ~/bazzite-ai-container*.sif && echo "✓ Containers downloaded"

# Test execution
ujust apptainer-exec-container-nvidia "python3 --version" && echo "✓ Container execution works"
```

### Test All Dev Tools in Container
```bash
ujust apptainer-exec-container-nvidia bash -c '
echo "=== Dev Tools Check ==="
python3 --version || echo "Python: MISSING"
node --version || echo "Node: MISSING"
npm --version || echo "npm: MISSING"
git --version || echo "Git: MISSING"
which vim || echo "vim: MISSING"
which docker || echo "docker: MISSING"
echo "=== Check Complete ==="
'
```

### Test CUDA/ML Libraries
```bash
ujust apptainer-exec-container-nvidia bash -c '
echo "=== CUDA/ML Libraries ==="
find /usr -name "libcudnn.so*" 2>/dev/null | head -1 || echo "cuDNN: NOT FOUND"
find /usr -name "libnvinfer.so*" 2>/dev/null | head -1 || echo "TensorRT: NOT FOUND"
echo "=== Check Complete ==="
'
```

---

## Time Estimates

| Task | Time | Notes |
|------|------|-------|
| devcontainers-CLI verification | 5 min | Quick checks only |
| Pull base container | 5-10 min | Depends on network speed |
| Test base container | 2-3 min | Interactive + command tests |
| Pull NVIDIA container | 10-15 min | Larger download |
| Test NVIDIA container | 3-5 min | Interactive + library checks |
| **Total (Fast Path)** | **25-35 min** | Without builds |
| Optional: Build configs | +30 min | Per config |
| **Total (Complete)** | **55-65 min** | With builds |

---

## Success Criteria Summary

**Minimum (Core Functionality):**
- ✓ devcontainer CLI installed and working
- ✓ Both .devcontainer configs valid
- ✓ Base container pulls and runs
- ✓ NVIDIA container pulls and runs
- ✓ All dev tools accessible in containers

**Recommended (Full Validation):**
- ✓ Above + container builds work
- ✓ Above + Podman/Docker testing
- ✓ Above + VS Code integration tested

**Comprehensive (Production Ready):**
- ✓ Above + GPU testing (if hardware available)
- ✓ Above + performance benchmarks
- ✓ Above + stress testing

---

## Next Steps After Testing

1. **Document Results:**
   - Which tests passed/failed
   - Any errors encountered
   - Performance observations

2. **Report Issues:**
   - File issues for any failures
   - Suggest improvements
   - Update documentation

3. **Use in Production:**
   - Start using ujust commands in workflows
   - Test VS Code devcontainer integration
   - Validate GPU access if hardware available

---

## Reference

- **Main Documentation:** `docs/CONTAINER.md`
- **GPU Setup:** `docs/HOST-SETUP-GPU.md`
- **Test Guide:** `testing/CONTAINER-TESTING-GUIDE.md`
- **Automated Scripts:** `testing/test-*.sh`
- **Summary:** `testing/TESTING-SUMMARY.md`
