---
title: Building Images
---

# Building Images

Learn how to build Bazzite AI container images, ISOs, and VM images.

## Overview

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🐳 Container Images
Build the base OS container image and development containers.

```bash
just build
just build-container
```
:::

:::{grid-item-card} 💿 ISO Installers
Build bootable ISO installer images.

```bash
just build-iso
```

{doc}`iso-build`
:::

:::{grid-item-card} 🖥️ VM Images
Build QCOW2 and raw disk images.

```bash
just build-qcow2
just run-vm
```
:::

:::{grid-item-card} 📦 Releases
Complete release workflow with torrents.

```bash
just release
```

{doc}`release-process`
:::

::::

## Quick Commands

### Container Images

```bash
# OS image
just build [image] [tag]
just rebuild  # Force rebuild

# Development containers
just build-container         # CPU-only
just build-container-nvidia  # GPU variant
```

### Bootable Images

```bash
# ISO installer
just build-iso [image] [tag]
just rebuild-iso

# VM images
just build-qcow2 [image] [tag]
just build-raw [image] [tag]

# Test in VM
just run-vm [image] [tag]
just run-vm-iso
```

## Build System

### Containerfile Architecture

```{admonition} Optimized layer caching
:class: tip

The build uses **9 separate RUN layers** for granular caching, with packages split by change frequency for maximum cache efficiency.
```

**Layer Strategy:**

- **Stable packages** (Layer 3): Core Fedora - ~80% cache hits
- **Moderate packages** (Layer 4): External repos - ~60% cache hits
- **Volatile config** (Layer 5): System settings - fast rebuilds (~30-60s)

### Build Performance

```{list-table}
:header-rows: 1
:widths: 40 30 30

* - Scenario
  - Build Time
  - Cache Usage
* - **First build**
  - 6-8 minutes
  - Builds all layers
* - **Config change**
  - 30-60 seconds
  - Uses 90% cached layers
* - **Package change**
  - 4-5 minutes
  - Uses 40-60% cached layers
* - **Unchanged**
  - Seconds
  - 100% cached
```

## Next Steps

::::{grid} 1 1 3 3
:gutter: 2

:::{grid-item-card} 💿 ISO Building
:link: iso-build
:link-type: doc

Detailed ISO building guide
:::

:::{grid-item-card} 📦 Release Process
:link: release-process
:link-type: doc

Complete release workflow
:::

:::{grid-item-card} 🧪 Testing
:link: ../testing/index
:link-type: doc

Testing your builds
:::

::::
