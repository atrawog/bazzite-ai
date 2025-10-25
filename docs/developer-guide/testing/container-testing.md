---
title: Container Testing Guide
---

# Container Testing Guide

Comprehensive automated testing for devcontainers-CLI and Bazzite AI containers.

## Test Scripts Overview

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} test-devcontainers-cli.sh
Tests devcontainers CLI installation and functionality

**Duration:** 5-15 min (without builds), 20-30 min (with builds)

**Output:** `devcontainers-cli-results.json`
:::

:::{grid-item-card} test-containers-apptainer.sh
Tests production Apptainer container workflow

**Duration:** 25-35 min (with pulls), 5-10 min (skip pulls)

**Output:** `apptainer-test-results.json`
:::

::::

## Quick Start

### Test devcontainers-CLI

```bash
./testing/test-devcontainers-cli.sh
```

**Tests performed:**
- Installation verification (command exists, version, PATH)
- CLI functionality (help, build, up, exec commands)
- Devcontainer configuration validation (JSON syntax, image references)
- Build testing (optional - builds both base and NVIDIA configs)

**Outputs:**
- `testing/devcontainers-cli-test.log` - Full test log
- `testing/devcontainers-cli-results.json` - Machine-readable results

### Test Apptainer Containers

```bash
# Full test (pulls containers)
./testing/test-containers-apptainer.sh

# Use existing containers
./testing/test-containers-apptainer.sh --skip-pull
```

**Tests performed:**
- Apptainer installation and ujust command availability
- Pull both containers via ujust (base + nvidia)
- Verify .sif files created and sizes correct
- Execute commands in containers via ujust
- Test tool availability (Python, Node.js, Git, etc.)
- Check for CUDA/ML libraries in NVIDIA container

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

::::{dropdown} Step-by-step manual testing

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

::::

### Test Apptainer Containers Manually

::::{dropdown} Step-by-step Apptainer testing

```bash
# Pull containers
ujust apptainer-pull-container
ujust apptainer-pull-container-nvidia

# Verify files
ls -lh ~/bazzite-ai-container*.sif
du -h ~/bazzite-ai-container*.sif

# Test interactive shell (base)
ujust apptainer-run-container
# Inside container:
python3 --version
node --version
git --version
exit

# Test command execution (NVIDIA)
ujust apptainer-exec-container-nvidia "nvidia-smi 2>&1 || echo 'No GPU'"
ujust apptainer-exec-container-nvidia "python3 --version"
```

::::

## Test Results Format

All test scripts generate JSON results:

```json
{
  "timestamp": "2025-10-25T12:00:00Z",
  "tests_run": 15,
  "tests_passed": 15,
  "tests_failed": 0,
  "success_rate": "100%",
  "duration": "25m 30s",
  "details": {
    "test_name": {
      "status": "passed|failed",
      "message": "Description",
      "duration": "5s"
    }
  }
}
```

**Review results:**

```bash
# Pretty-print JSON
cat testing/apptainer-test-results.json | jq

# Check success rate
jq '.success_rate' testing/apptainer-test-results.json

# List failed tests
jq '.details | to_entries[] | select(.value.status == "failed")' testing/apptainer-test-results.json
```

## Troubleshooting

### Test Script Fails to Run

::::{dropdown} Solutions

```bash
# Make scripts executable
chmod +x testing/*.sh

# Check dependencies
which jq apptainer podman

# Install missing tools
sudo dnf install jq apptainer podman
```

::::

### Container Pull Failures

::::{dropdown} Solutions

```bash
# Check network connectivity
ping ghcr.io

# Check authentication (if needed)
podman login ghcr.io

# Try manual pull
podman pull ghcr.io/atrawog/bazzite-ai-container:latest
```

::::

### devcontainers-CLI Not Found

::::{dropdown} Solutions

```bash
# Check installation
which devcontainer

# Check PATH
echo $PATH | grep npm-global

# Reinstall
ujust install-devcontainers-cli

# Verify installation
devcontainer --version
```

::::

## Continuous Integration

These test scripts are designed for CI/CD integration:

```yaml
# Example GitHub Actions workflow
jobs:
  test-containers:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install dependencies
        run: sudo dnf install -y apptainer jq

      - name: Test Apptainer containers
        run: ./testing/test-containers-apptainer.sh

      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: testing/*-results.json
```

## Related Documentation

```{seealso}
- {doc}`manual-testing` - Quick manual testing reference
- {doc}`../../user-guide/containers/usage` - Container usage guide
- Test reports in `docs/archive/test-reports/`
```
