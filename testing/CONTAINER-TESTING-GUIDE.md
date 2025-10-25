# Container Testing Guide

This directory contains comprehensive test scripts for validating devcontainers-cli and bazzite-ai container functionality.

## Test Scripts Created

### 1. test-devcontainers-cli.sh
**Purpose:** Tests devcontainers CLI installation and functionality

**Tests performed:**
- Installation verification (command exists, version, PATH)
- CLI functionality (help, build, up, exec commands)
- Devcontainer configuration validation (JSON syntax, image references)
- Build testing (optional - builds both base and NVIDIA configs)

**Usage:**
```bash
./testing/test-devcontainers-cli.sh
```

**Expected duration:** 5-15 minutes (without builds), 20-30 minutes (with builds)

**Outputs:**
- `testing/devcontainers-cli-test.log` - Full test log
- `testing/devcontainers-cli-results.json` - Machine-readable results

### 2. test-containers-apptainer.sh
**Purpose:** Tests production Apptainer container workflow using ujust commands

**Tests performed:**
- Apptainer installation and ujust command availability
- Pull both containers via ujust (base + nvidia)
- Verify .sif files created and sizes correct
- Execute commands in containers via ujust
- Test tool availability (Python, Node.js, Git, etc.)
- Check for CUDA/ML libraries in NVIDIA container

**Usage:**
```bash
# Full test (pulls containers)
./testing/test-containers-apptainer.sh

# Use existing containers
./testing/test-containers-apptainer.sh --skip-pull
```

**Expected duration:** 25-35 minutes (with pulls), 5-10 minutes (skip pulls)

**Outputs:**
- `testing/apptainer-test.log` - Full test log
- `testing/apptainer-test-results.json` - Machine-readable results
- `~/bazzite-ai-container_latest.sif` - Base container (~2GB)
- `~/bazzite-ai-container-nvidia_latest.sif` - NVIDIA container (~4GB)

## ujust Commands Tested

### Apptainer Commands (Primary Production Workflow)

```bash
# Information
ujust apptainer-info                    # Show Apptainer system info

# Base Container (CPU-only)
ujust apptainer-pull-container          # Pull base .sif (~2GB)
ujust apptainer-run-container           # Run interactively
ujust apptainer-exec-container CMD      # Execute command

# NVIDIA Container (GPU-enabled)
ujust apptainer-pull-container-nvidia   # Pull NVIDIA .sif (~4GB)
ujust apptainer-run-container-nvidia    # Run with GPU support
ujust apptainer-exec-container-nvidia CMD # Execute with GPU

# Development Tools
ujust install-devcontainers-cli         # Install devcontainers CLI
ujust install-dev-tools                 # Install all dev tools
ujust check-claude-code                 # Verify Claude Code
ujust setup-gpu-containers              # Setup GPU access (if NVIDIA)
```

## Testing Workflow Recommendations

### Fast Path (~45 minutes)
Recommended for quick validation:

```bash
# 1. Test devcontainers-cli (10 min)
./testing/test-devcontainers-cli.sh

# 2. Test Apptainer containers (25 min)
./testing/test-containers-apptainer.sh

# 3. Review results
cat testing/devcontainers-cli-results.json | jq
cat testing/apptainer-test-results.json | jq
```

### Complete Path (~90-120 minutes)
Full validation including local builds:

```bash
# 1. devcontainers-cli with builds (30 min)
./testing/test-devcontainers-cli.sh

# 2. Apptainer containers (30 min)
./testing/test-containers-apptainer.sh

# 3. Podman/Docker testing (30 min)
# Pull and test via just commands
just pull-container
just run-container
just pull-container-nvidia
just run-container-nvidia
just test-cuda-container

# 4. Optional: Local builds (60+ min)
just build-container
just build-container-nvidia
```

## Manual Testing Examples

### Test devcontainers-cli Manually

```bash
# Check installation
devcontainer --version
which devcontainer

# Build base config
devcontainer build \
  --workspace-folder . \
  --config .devcontainer/devcontainer-base.json

# Build NVIDIA config
devcontainer build \
  --workspace-folder . \
  --config .devcontainer/devcontainer.json

# Start container
devcontainer up --workspace-folder . --config .devcontainer/devcontainer-base.json

# Execute command
devcontainer exec --workspace-folder . python3 --version
```

### Test Apptainer Containers Manually

```bash
# Pull containers
ujust apptainer-pull-container
ujust apptainer-pull-container-nvidia

# Verify files
ls -lh ~/bazzite-ai-container_latest.sif
ls -lh ~/bazzite-ai-container-nvidia_latest.sif

# Run interactively
ujust apptainer-run-container
# Inside container:
#   whoami
#   python3 --version
#   node --version
#   exit

# Execute commands
ujust apptainer-exec-container-nvidia "python3 --version"
ujust apptainer-exec-container-nvidia "ls -la /workspace"

# Check for ML libraries
ujust apptainer-exec-container-nvidia "find /usr -name 'libcudnn*' | head -5"
```

## Success Criteria

### devcontainers-cli
- ✓ CLI installed and in PATH
- ✓ All subcommands available (build, up, exec)
- ✓ Both .devcontainer configs are valid JSON
- ✓ Configs reference correct container images
- ✓ Builds complete successfully (if tested)

### Apptainer Containers
- ✓ Both .sif files download successfully
- ✓ Base container ~2GB, NVIDIA container ~3-4GB
- ✓ Interactive shells work (ujust apptainer-run-container*)
- ✓ Command execution works (ujust apptainer-exec-container-nvidia)
- ✓ All dev tools present (Python, Node.js, Git, etc.)
- ✓ CUDA/ML libraries found in NVIDIA container
- ✓ Workspace binding functional (/workspace)

## Troubleshooting

### devcontainer command not found
```bash
# Reinstall via ujust
ujust install-devcontainers-cli

# Or check PATH
echo $PATH | grep npm-global
source ~/.bashrc
```

### Apptainer .sif files not found
```bash
# Check if pulls completed
ls -lh ~/*.sif

# Re-pull if needed
ujust apptainer-pull-container
ujust apptainer-pull-container-nvidia
```

### Container pulls timeout
```bash
# Check network connectivity
ping -c 3 ghcr.io

# Check disk space (need ~7GB free)
df -h ~

# Try manual pull
cd ~
apptainer pull docker://ghcr.io/atrawog/bazzite-ai-container:latest
```

### Tests fail with "command not found"
```bash
# Ensure ujust is available
which ujust

# Check if running from correct directory
cd /var/home/atrawog/Repo/bazzite-ai/bazzite-ai
./testing/test-containers-apptainer.sh
```

## Files Generated

### Test Scripts
- `testing/test-devcontainers-cli.sh` - devcontainers CLI tests
- `testing/test-containers-apptainer.sh` - Apptainer container tests

### Test Results
- `testing/devcontainers-cli-test.log` - devcontainers test log
- `testing/devcontainers-cli-results.json` - devcontainers results
- `testing/apptainer-test.log` - Apptainer test log
- `testing/apptainer-test-results.json` - Apptainer results

### Container Files
- `~/bazzite-ai-container_latest.sif` - Base container (~2GB)
- `~/bazzite-ai-container-nvidia_latest.sif` - NVIDIA container (~3-4GB)

## Next Steps

After running tests:

1. **Review Results:**
   ```bash
   cat testing/*-results.json | jq
   grep -i "fail\|pass" testing/*.log
   ```

2. **Generate Report:**
   - Document test outcomes
   - Note any failures or issues
   - Compare with expected behavior
   - Create CONTAINERS-TEST-REPORT.md

3. **Test in Production:**
   - Use ujust commands in actual workflows
   - Test VS Code devcontainer integration
   - Validate GPU access (if NVIDIA hardware available)

4. **Report Issues:**
   - Document any bugs found
   - Note missing features
   - Suggest improvements

## Additional Resources

- **Main Documentation:** `docs/CONTAINER.md`
- **GPU Setup:** `docs/HOST-SETUP-GPU.md`
- **Repository Justfile:** `Justfile` (development commands)
- **System Justfiles:** `system_files/usr/share/ublue-os/just/*.just` (ujust commands)
