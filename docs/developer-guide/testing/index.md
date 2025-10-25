---
title: Testing Guide
---

# Testing Guide

Comprehensive testing guides for Bazzite AI containers, ujust commands, and system components.

## Overview

Bazzite AI provides testing utilities for rapid iteration on ujust recipes and comprehensive container validation.

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🧪 ujust Recipe Testing
Test justfile recipes locally without rebuilding the entire OS image.

**Time:** Seconds to minutes
**Benefit:** 60x faster development cycle

See `testing/README.md` for ujust testing utilities
:::

:::{grid-item-card} 🐳 Container Testing
Comprehensive container functionality validation.

**Time:** 25-45 minutes
**Coverage:** Apptainer, devcontainers-CLI, Podman/Docker

{doc}`./container-testing`
:::

::::

## Quick Testing Workflows

### Fast Path: ujust Recipe Testing (Seconds)

```bash
# Test recipe changes instantly without system modifications
./testing/ujust-test install-devcontainers-cli
./testing/ujust-test install-dev-tools
```

```{tip}
This is **60x faster** than rebuilding the entire OS image! Use this for rapid iteration.
```

### Standard Path: Container Validation (45 min)

```bash
# 1. Test devcontainers-CLI (10 min)
./testing/test-devcontainers-cli.sh

# 2. Test Apptainer containers (25 min)
./testing/test-containers-apptainer.sh

# 3. Review results
cat testing/*-results.json | jq
```

### Complete Path: Full Validation (90-120 min)

```bash
# Run all automated tests + manual verification
./testing/test-devcontainers-cli.sh
./testing/test-containers-apptainer.sh
just pull-container && just run-container
just pull-container-nvidia && just test-cuda-container
```

## Testing Methods Comparison

```{list-table}
:header-rows: 1
:widths: 25 25 25 25

* - Method
  - Speed
  - Risk
  - Use Case
* - **Test Wrapper**
  - ⚡ Instant
  - ✅ None
  - Quick syntax/logic checks
* - **usroverlay**
  - 🐢 Medium
  - ⚠️ Low
  - Full environment testing
* - **Full Rebuild**
  - 🐌 Slow
  - ✅ None
  - Production deployment
```

## Available Testing Tools

### Automated Test Scripts

```{list-table}
:header-rows: 1
:widths: 40 60

* - Script
  - Purpose
* - `testing/test-devcontainers-cli.sh`
  - Tests devcontainers CLI installation and functionality
* - `testing/test-containers-apptainer.sh`
  - Tests Apptainer container workflow
* - `testing/ujust-test`
  - Test wrapper for ujust recipes
* - `testing/apply-usroverlay.sh`
  - Helper for rpm-ostree usroverlay testing
```

### Test Output Files

All test scripts generate structured results:

- `testing/*-test.log` - Full test logs
- `testing/*-results.json` - Machine-readable results

## Example Workflows

### Workflow 1: Testing ujust Recipe Changes

```{admonition} Problem
:class: note

You modified a ujust recipe in `system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just` and want to test it immediately.
```

**Traditional approach:** Rebuild entire OS image (6-8 minutes)
**Fast approach:** Use test wrapper (<10 seconds)

```bash
# 1. Edit the recipe
vim system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just

# 2. Test immediately
./testing/ujust-test install-devcontainers-cli

# 3. If successful, commit
git add system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just
git commit -m "Fix: devcontainers-cli verification check"
```

### Workflow 2: Validating Container Functionality

```bash
# Run automated container tests
./testing/test-containers-apptainer.sh

# Review results
cat testing/apptainer-test-results.json | jq

# Manual spot checks
ujust apptainer-run-container
# Inside container:
python3 --version
node --version
exit
```

### Workflow 3: Pre-Release Validation

```bash
# 1. Test all components
./testing/test-devcontainers-cli.sh
./testing/test-containers-apptainer.sh

# 2. Test ISO build
just build-iso
just run-vm-iso

# 3. Verify flatpaks (if modified)
# See docs/archive/test-reports/flatpaks.md
```

## Test Coverage

### ujust Commands Tested

::::{tab-set}

:::{tab-item} Apptainer
```bash
ujust apptainer-info
ujust apptainer-pull-container
ujust apptainer-run-container
ujust apptainer-pull-container-nvidia
ujust apptainer-run-container-nvidia
```
:::

:::{tab-item} Development Tools
```bash
ujust install-devcontainers-cli
ujust install-dev-tools
ujust install-pixi
ujust check-claude-code
ujust setup-gpu-containers
```
:::

:::{tab-item} Containers
```bash
just pull-container
just run-container
just pull-container-nvidia
just test-cuda-container
```
:::

::::

## Next Steps

::::{grid} 1 1 3 3
:gutter: 2

:::{grid-item-card} 🧪 ujust Testing
Test justfile recipes locally

See `testing/README.md` for details
:::

:::{grid-item-card} 🐳 Container Testing
:link: container-testing
:link-type: doc

Comprehensive container validation
:::

:::{grid-item-card} 📋 Manual Testing
:link: manual-testing
:link-type: doc

Quick reference for manual tests
:::

::::

```{seealso}
- {doc}`../building/index` - Building images
- {doc}`../../user-guide/containers/index` - Container usage
- Test reports in `docs/archive/test-reports/`
```
