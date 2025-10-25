---
title: Contributing Guide
---

# Contributing to Bazzite AI

Thank you for your interest in contributing to Bazzite AI! This guide will help you understand the repository structure and contribution workflow.

```{admonition} Fork Context
:class: note

This repository is a fork of [ublue-os/bazzite-dx](https://github.com/ublue-os/bazzite-dx) with custom AI/ML-focused branding and tooling. We maintain compatibility with upstream while adding specialized features.
```

## Repository Structure

This fork maintains **two branches**:

::::{grid} 1 1 2 2
:gutter: 2

:::{grid-item-card} main
:class-card: border-primary

**Development Branch**

Contains Bazzite AI branding and customizations. All development happens here.
:::

:::{grid-item-card} upstream-main
:class-card: border-secondary

**Tracking Branch**

Clean mirror of `ublue-os/bazzite-dx:main` for upstream sync.
:::

::::

## Contribution Types

::::{tab-set}

:::{tab-item} Bazzite AI Features
**Adding features specific to Bazzite AI**

1. Create feature branch from `main`
2. Make your changes
3. Test thoroughly
4. Submit PR to `main`

```bash
git checkout main
git checkout -b feature/my-feature
# Make changes
git commit -m "Add: My awesome feature"
git push origin feature/my-feature
```
:::

:::{tab-item} Upstream Contributions
**Contributing improvements back to ublue-os/bazzite-dx**

See "Contributing Back to Upstream" section below for the full workflow.
:::

:::{tab-item} Bug Fixes
**Fixing bugs in Bazzite AI**

Same as feature additions - branch from `main` and submit PR.
:::

::::

## Syncing Updates from Upstream

To pull the latest changes from upstream Bazzite DX:

```bash
# Fetch latest upstream changes
git fetch upstream

# Switch to main branch
git checkout main

# Merge upstream changes
git merge upstream/main

# Resolve any conflicts (especially in branding files)
# Push the merged changes
git push origin main
```

### Expected Merge Conflicts

```{warning}
When merging upstream changes, you will typically encounter conflicts in branding-specific files. **Always favor the fork-specific branding** in these files.
```

Common conflict files:

::::{grid} 1 1 2 3
:gutter: 2

:::{grid-item-card} Configuration
- `README.md`
- `Justfile`
- `Containerfile`
- `iso.toml`
:::

:::{grid-item-card} CI/CD
- `.github/workflows/build.yml`
- `.github/CODEOWNERS`
- `artifacthub-repo.yml`
:::

:::{grid-item-card} Documentation
- `CLAUDE.md`
- `CONTRIBUTING.md`
- `system_files/usr/share/ublue-os/just/95-bazzite-ai.just`
:::

::::

#### Resolution Strategy

```{dropdown} Example: Resolving Justfile conflicts
:open:

**Upstream change:**
```diff
- DEFAULT_TAG := "latest"
+ DEFAULT_TAG := "stable"
```

**Fork change:**
```diff
IMAGE_NAME := "bazzite-ai"
REPO_ORGANIZATION := "atrawog"
```

**Resolution:** Keep fork branding + accept upstream logic updates
```bash
IMAGE_NAME := "bazzite-ai"           # Keep fork
REPO_ORGANIZATION := "atrawog"        # Keep fork
DEFAULT_TAG := "stable"               # Accept upstream
```
```

## Contributing Back to Upstream

To contribute improvements back to `ublue-os/bazzite-dx`:

### Step 1: Create Feature Branch from `upstream-main`

```bash
# Switch to upstream-main branch
git checkout upstream-main

# Pull latest upstream changes
git pull upstream main

# Create a feature branch
git checkout -b feature/upstream-contribution
```

### Step 2: Cherry-Pick or Develop Changes

::::{tab-set}

:::{tab-item} Cherry-Pick Existing
If the change exists in `main`:

```bash
# Cherry-pick specific commits (exclude branding changes!)
git cherry-pick <commit-hash>

# Review the changes to ensure no fork branding
git show HEAD
```
:::

:::{tab-item} Develop Fresh
Develop the feature directly on the feature branch:

```bash
# Make changes
vim build_files/20-install-apps.sh

# Commit without fork references
git commit -m "Add: Support for new development tool"
```
:::

::::

### Step 3: Ensure No Fork Branding

```{danger}
**Critical Check**: Verify that no fork-specific branding appears in your contribution!
```

Run these checks before submitting:

```bash
# Check for bazzite-ai references
git diff upstream/main | grep -i "bazzite-ai"

# Check for atrawog references
git diff upstream/main | grep -i "atrawog"

# Review all changed files
git diff upstream/main --name-only
```

If found, those changes should **NOT** be in your upstream contribution.

### Step 4: Push and Create Pull Request

```bash
# Push feature branch to your fork
git push origin feature/upstream-contribution
```

Then create a Pull Request from:
```
atrawog/bazzite-ai:feature/upstream-contribution
→ ublue-os/bazzite-dx:main
```

## File Categories

### ✅ Compatible with Upstream

These files can be contributed back **without modification**:

```{list-table}
:header-rows: 1
:widths: 40 60

* - File
  - Notes
* - `build_files/00-image-info.sh`
  - Uses build args (portable)
* - `build_files/20-install-apps.sh`
  - Package installations
* - `build_files/40-services.sh`
  - Service configuration
* - `build_files/50-fix-opt.sh`
  - Opt directory fixes
* - `build_files/99-build-initramfs.sh`
  - Initramfs rebuild
* - `build_files/999-cleanup.sh`
  - Cleanup scripts
* - `image.toml`
  - VM configuration
* - `image-versions.yaml`
  - Base image tracking
* - `.github/renovate.json5`
  - Dependency automation
```

### ❌ Fork-Specific Files

These files should **NEVER** be contributed to upstream:

```{list-table}
:header-rows: 1
:widths: 40 60

* - File
  - Reason
* - `README.md`
  - Contains fork URLs and description
* - `Justfile`
  - Contains atrawog/bazzite-ai defaults
* - `Containerfile`
  - Contains bazzite-ai image name
* - `iso.toml`
  - Contains ghcr.io/atrawog/bazzite-ai URL
* - `.github/workflows/build.yml`
  - Contains bazzite-ai transform
* - `.github/CODEOWNERS`
  - Contains @atrawog
* - `artifacthub-repo.yml`
  - Contains atrawog owner
* - `CLAUDE.md`
  - Fork-specific documentation
* - `CONTRIBUTING.md`
  - This file (fork-specific)
* - `system_files/.../95-bazzite-ai.just`
  - Fork-specific commands
```

## Development Workflow

### Local Testing

```bash
# Build container image locally
just build

# Build and test in VM
just rebuild-vm
just run-vm

# Build ISO installer
just build-iso
```

### Code Style

```{tip}
Follow these guidelines for consistency:
```

- **Bash scripts**: Use ShellCheck linting
- **Justfile**: Run `just fix` for auto-formatting
- **Markdown**: Follow MyST Markdown syntax
- **Commits**: Use conventional commit messages

#### Conventional Commits

```
<type>: <description>

[optional body]
```

**Types:**
- `Add:` - New features
- `Fix:` - Bug fixes
- `Docs:` - Documentation changes
- `Refactor:` - Code restructuring
- `Test:` - Adding/updating tests
- `CI:` - CI/CD changes

**Example:**
```bash
git commit -m "Add: Claude Code CLI installation recipe

Adds ujust install-claude-code command for installing
Claude Code CLI in user home directory."
```

## Questions?

::::{grid} 1 1 2 2
:gutter: 2

:::{grid-item-card} 🐛 Fork Issues
For Bazzite AI-specific issues:
[atrawog/bazzite-ai/issues](https://github.com/atrawog/bazzite-ai/issues)
:::

:::{grid-item-card} 💬 Discussions
Ask questions and share ideas:
[GitHub Discussions](https://github.com/atrawog/bazzite-ai/discussions)
:::

:::{grid-item-card} 🔄 Upstream
For upstream contributions:
[ublue-os/bazzite-dx](https://github.com/ublue-os/bazzite-dx)
:::

:::{grid-item-card} 📚 Documentation
Browse comprehensive guides:
[Documentation Home](../index.md)
:::

::::

```{seealso}
- {doc}`../developer-guide/building/index` - Building ISOs and images
- {doc}`../developer-guide/testing/index` - Testing guidelines
- [ublue-os contributing](https://github.com/ublue-os/bazzite-dx/blob/main/CONTRIBUTING.md) - Upstream guidelines
```
