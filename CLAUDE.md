# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is Bazzite AI - a custom fork of [Bazzite](https://github.com/ublue-os/bazzite) with AI/ML-focused tooling and customizations. It's a container-based immutable Linux distribution built on top of Bazzite, extending it with developer tooling.

**⚠️ Important**: Bazzite AI **only supports KDE Plasma variants**. GNOME variants are not officially supported.

Key technologies:
- **Base**: ublue-os/bazzite-nvidia-open (KDE Plasma) with open NVIDIA drivers (works on all GPUs)
- **Desktop**: KDE Plasma only
- **Build System**: Containerfile-based OSTree image builds
- **Task Runner**: Just (justfile)
- **Package Manager**: dnf5, flatpak, homebrew (for fonts)
- **Container Tools**: Apptainer (HPC/research), Podman/Docker, WinBoat (Windows apps)
- **CI/CD**: GitHub Actions with buildah/cosign signing

## Commit Message Convention

**All commits and PR titles must follow semantic commit message format.** This is enforced via automated validation.

### Required Format

```
<Type>: <description>
```

**Allowed types:** `Fix:`, `Feat:`, `Docs:`, `Chore:`, `Refactor:`, `Style:`

**Examples:**
- `Fix: correct path handling in build script`
- `Feat: add GPU support for containers`
- `Docs: update installation guide`
- `Chore: update dependencies to latest versions`
- `Refactor: simplify build cache logic`
- `Style: format justfiles with proper indentation`

### Why This Matters

1. **Automated Workflows**: Commit types trigger specific CI/CD actions:
   - `Feat:`/`Fix:`/`Refactor:` → Full build and tests
   - `Docs:` → Documentation build only
   - `Chore:` → Skip expensive CI on feature branches

2. **Clean History**: Makes git log readable and searchable
3. **Release Automation**: Enables automated changelog generation
4. **Required Checks**: PRs cannot merge without passing semantic validation

### Validation

Two automated workflows enforce this convention:
- **semantic-pr.yml** - Validates PR titles
- **semantic-commits.yml** - Validates all commits in PR/push

**These are required status checks** - failed validation blocks merging.

### Full Documentation

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for complete guidelines, including:
- Detailed type descriptions and examples
- How to fix failed validation
- Migration from legacy prefixes (`Add:`, `Update:`, etc.)
- Pre-commit hooks and linting setup
- Pull request process
- Development workflow

### Local Pre-commit Hooks

Bazzite AI includes pre-commit hooks to validate code quality **before** commits reach CI:

**Quick setup:**
```bash
ujust install-dev-environment  # One-time setup (installs everything)
ujust lint                      # Run linters manually
```

**What's validated:**
- Shell scripts (ShellCheck)
- Markdown (markdownlint)
- YAML (yamllint)
- TOML (taplo)
- Justfiles (just --fmt)
- Commit messages (semantic prefixes)

**Hooks run automatically** on `git commit`. See CONTRIBUTING.md for details.

## Architecture

### Container-Based OS Image

This is NOT a traditional application repository. It builds bootable container images using:

1. **Base Image**: Starts from `ghcr.io/ublue-os/bazzite-nvidia-open:stable` (unified base)
2. **Build Process**: Simplified Containerfile architecture optimized for buildah registry cache compatibility:
   - **Direct file copies** instead of bind mounts (ensures buildah can query external cache)
   - **9 separate RUN layers** for granular caching (each script is a separate layer)
   - **No cache mounts** (DNF5, pip) - explicit cleanup within each layer instead
   - **Layer caching strategy**: Relies purely on buildah's native registry cache
   - Copies `system_files/` (runtime config) and `build_files/` (build scripts) via COPY commands
   - Executes build scripts directly in separate layers (bypasses build.sh orchestrator)
   - Installs developer tools (VS Code, Docker, Android tools, BPF tools, etc.)
   - Always installs nvidia-container-toolkit for GPU container support
   - Configures system settings and services
   - Explicit cleanup (`dnf5 clean all && rm -rf /var/cache/dnf5/*`) in package installation scripts
3. **Output**: Signed container image pushed to GitHub Container Registry

**Build Cache Performance:**
- First build: ~6-8 minutes (builds all layers)
- Incremental ujust/system_files change: **~15-30 seconds** (12-25x faster) ⚡
- Incremental config change (30-system-config.sh): **~30-60 seconds** (5-10x faster)
- Incremental package change (external): **~2-3 minutes** (~2x faster)
- Incremental package change (base): **~4-5 minutes** (~1.5x faster)
- Unchanged builds: Uses cached layers exclusively (seconds)

### Build Script Execution Order

**Layered Architecture:** Each script executes in a separate Containerfile RUN layer for optimal caching. Package installations are split into 3 layers by change frequency for maximum cache efficiency:

**Directory Structure:**
```
build_files/
├── os/                              # OS image build scripts
│   ├── 00-image-info.sh            # Image metadata
│   ├── 10-base-packages.sh         # Core Fedora packages (STABLE)
│   ├── 20-external-packages.sh     # External repos/COPR (MODERATE)
│   ├── 30-system-config.sh         # System configuration (VOLATILE)
│   ├── 40-services.sh              # Service enables
│   ├── 50-fix-opt.sh               # /opt directory fixes
│   ├── 60-clean-base.sh            # Justfile import
│   ├── 99-build-initramfs.sh       # Initramfs rebuild (EXPENSIVE but STABLE)
│   ├── 100-copy-system-files.sh    # Copy runtime configs (VOLATILE)
│   └── 999-cleanup.sh              # Final cleanup
└── shared/                          # Shared utilities (not currently used)
    └── log.sh                       # Logging functions
```

**Layer Execution (Granular COPY Architecture):**

Each script is copied individually RIGHT BEFORE execution for optimal cache invalidation:

**Layer 1**: Create `/var/roothome` directory
**Layer 2**: COPY `os/00-image-info.sh`
**Layer 3**: RUN `os/00-image-info.sh` - Sets image metadata
**Layer 4**: COPY `os/10-base-packages.sh`
**Layer 5**: RUN `os/10-base-packages.sh` - **Core Fedora packages** (~500MB, STABLE)
**Layer 6**: COPY `os/20-external-packages.sh`
**Layer 7**: RUN `os/20-external-packages.sh` - **External repos/COPR/VS Code/Docker/nvidia-container-toolkit** (~100MB, MODERATE)
**Layer 8**: COPY `os/30-system-config.sh`
**Layer 9**: RUN `os/30-system-config.sh` - **System configuration** (~10MB, VOLATILE)
**Layer 10**: COPY `os/40-services.sh`
**Layer 11**: RUN `os/40-services.sh` - Enables/disables systemd services
**Layer 12**: COPY `os/50-fix-opt.sh`
**Layer 13**: RUN `os/50-fix-opt.sh` - Fixes /opt directory permissions
**Layer 14**: COPY `os/60-clean-base.sh`
**Layer 15**: RUN `os/60-clean-base.sh` - Imports justfile, removes gaming-specific configs
**Layer 16**: COPY `os/99-build-initramfs.sh`
**Layer 17**: RUN `os/99-build-initramfs.sh` - **Rebuilds initramfs** (EXPENSIVE ~30-60s, but STABLE)
**Layer 18**: COPY `system_files/` - Runtime configs (ujust, flatpaks, VS Code settings)
**Layer 19**: COPY `os/100-copy-system-files.sh`
**Layer 20**: RUN `os/100-copy-system-files.sh` - Copy `system_files/` to root (VOLATILE)
**Layer 21**: COPY `os/999-cleanup.sh`
**Layer 22**: RUN `os/999-cleanup.sh` - Final cleanup, container lint
**Layer 23**: Remove `/tmp/build_files` and `/tmp/system_files`

**Cache Strategy:**

**Granular Invalidation:** Each script copied individually before execution
- Changing script N only invalidates layers from N onwards
- Example: Editing `100-copy-system-files.sh` only rebuilds layers 19-23 (~15-30s)
- Example: Editing `30-system-config.sh` only rebuilds layers 8-23 (~1-2min)

**Package Layer Split:** Installations organized by stability
- **STABLE** (Layers 4-5): Core packages change rarely → best cache hit rate (~80%)
- **MODERATE** (Layers 6-7): External dependencies change occasionally → good cache hit rate (~60%)
- **VOLATILE** (Layers 8-9): Configuration changes frequently → small/fast rebuilds

**Optimal Ordering:** Expensive operations placed BEFORE volatile content
- Initramfs rebuild (Layer 17, ~30-60s) runs BEFORE system_files copy (Layers 18-20)
- Ujust file changes no longer trigger kernel/initramfs rebuilds
- 600MB of packages remain cached when only configs change

**Performance:**
- Ujust-only changes: rebuild only layers 18-23 (~15-30s) vs previous ~6 minutes
- Config-only changes: rebuild only layers 8-23 (~30-60s) vs previous ~4-5 minutes
- Package changes: Use cached layers below the changed script

### Apptainer Integration

All variants include **Apptainer** (formerly Singularity) for HPC-style container workflows:

- **Container Variants**: `bazzite-ai-container` (base) and `bazzite-ai-container-nvidia` (GPU)
- **GPU Support**: Native via `--nv` flag (no nvidia-container-toolkit needed)
- **Format**: Single .sif files for reproducibility
- **Use Cases**: Research, compute clusters, scientific computing

Quick usage:
```bash
# GPU Development (NVIDIA)
ujust apptainer-pull-container-nvidia   # Download NVIDIA container
ujust apptainer-run-container-nvidia    # Interactive shell with GPU

# CPU-Only Development
ujust apptainer-pull-container          # Download base container
ujust apptainer-run-container           # Interactive shell (CPU)
```

### WinBoat Integration (Windows App Support)

**WinBoat** enables running Windows applications with seamless Linux integration:

- **Purpose**: Run Windows-only software without Wine or dual-boot
- **Technology**: Containerized Windows VM + RemoteApp protocol
- **Integration**: Windows apps appear as native Linux windows
- **Requirements**: Docker CE (pre-installed), 4GB RAM, 2 CPU threads

Quick usage:
```bash
# Launch WinBoat GUI
winboat

# First-time setup will download Windows container
# Configure through the GUI, then launch Windows apps
```

**Note**: WinBoat is beta software. Requires ~32GB disk space for Windows container.

### System Files Structure

`system_files/` contains files copied to the OS image root:
- `etc/skel/` - Default user home directory skeleton (VS Code settings)
- `etc/ublue-os/system_flatpaks` - List of flatpak apps to install
- `usr/bin/` - Custom scripts (e.g., `gamemode-nested`)
- `usr/share/ublue-os/just/` - ujust recipes for end-user commands
- `usr/share/ublue-os/*-setup.hooks.d/` - Setup hooks for user/privileged initialization

## Common Development Commands

### Building Container Images

```bash
# Build the container image locally
just build [target_image] [tag]
# Examples:
just build bazzite-ai latest
just build  # Uses defaults from env vars

# The build uses environment variables:
# - IMAGE_NAME (default: bazzite-ai)
# - DEFAULT_TAG (default: latest)
# - REPO_ORGANIZATION (default: ublue-os)
```

### Building Virtual Machine Images

Uses bootc-image-builder (BIB) to create bootable VMs/ISOs from container images:

```bash
# Build QCOW2 VM image (requires sudo for rootful podman)
just build-qcow2 [target_image] [tag]
just rebuild-qcow2  # Rebuilds container first

# Build raw disk image
just build-raw [target_image] [tag]

# Build ISO installer
just build-iso [target_image] [tag]

# Aliases for QCOW2
just build-vm
just rebuild-vm
```

Output goes to `output/qcow2/`, `output/raw/`, or `output/bootiso/`.

### Running Virtual Machines

```bash
# Run VM in browser-based viewer (uses qemu-docker)
just run-vm-qcow2 [target_image] [tag]
just run-vm  # Alias for run-vm-qcow2
just run-vm-iso

# Will auto-build if image doesn't exist
# Opens web interface on http://localhost:8006+ (auto-increments port if busy)
# Default VM specs: 4 cores, 8GB RAM, 64GB disk, TPM, GPU passthrough
```

### Repository Maintenance

```bash
# Check justfile syntax
just check

# Auto-format all justfiles
just fix

# Clean build artifacts
just clean
just sudo-clean  # For rootful podman artifacts

# Clean release artifacts (ISOs, torrents, releases/ directory)
just release-clean
```

**Note:** The `releases/` directory containing ISO images and torrents is git-ignored.

## Documentation System

This project uses **Jupyter Book** with **MyST Markdown** for professional, publication-quality documentation. All documentation is automatically built and deployed to GitHub Pages on every push to the main branch.

**Live Documentation:** https://atrawog.github.io/bazzite-ai/

### Critical Rules for Documentation

**⚠️ IMPORTANT ENFORCEMENT RULES:**

1. **ALL new markdown files MUST be created in `docs/` directory**
   - ✅ Correct: `docs/user-guide/new-feature.md`
   - ❌ Wrong: `new-feature.md` (in repository root)
   - **Exceptions**: Only `README.md` and `CLAUDE.md` are allowed at repository root

2. **ALL documentation MUST use MyST Markdown syntax**
   - Standard markdown is insufficient for professional documentation
   - Use MyST directives, roles, and features (see examples below)
   - Plain markdown will work but misses powerful features

3. **ALL new pages MUST be added to `docs/_toc.yml`**
   - Pages not in table of contents won't appear in navigation
   - Maintain hierarchical structure for logical organization

4. **Test locally before committing**
   - Always run `just docs-build` to verify syntax
   - Use `just docs-serve` for live preview with auto-reload
   - Fix any warnings or errors before pushing

### Technology Stack

- **Jupyter Book 2.0**: Publication-quality book building system (v2.0.0-b3 pre-release)
- **MyST Markdown**: Extended markdown with directives, roles, cross-references
- **MyST Engine**: Node.js-based documentation engine (replaces Sphinx in JB 2.0)
- **MyST Book Theme**: Modern, mobile-responsive theme
- **Pixi**: Fast, reproducible Python environment manager
- **GitHub Pages**: Automatic deployment on push to main branch

**Note**: Jupyter Book 2.0 is a major architectural change from 1.x. It uses the MyST engine instead of Sphinx, with a Node.js runtime for faster builds and modern web features.

### Documentation Structure

```
docs/
├── myst.yml                          # Jupyter Book 2.0 configuration (replaces _config.yml + _toc.yml)
├── index.md                          # Landing page
├── requirements.txt                  # DEPRECATED (use pixi.toml)
│
├── getting-started/
│   ├── index.md                      # Getting started overview
│   └── contributing.md               # Contributing guide
│
├── user-guide/
│   ├── index.md                      # User guide overview
│   ├── containers/
│   │   ├── index.md                  # Container overview
│   │   ├── usage.md                  # Container usage
│   │   └── gpu-setup.md              # GPU setup guide
│   └── winboat.md                    # Windows app support
│
├── developer-guide/
│   ├── index.md                      # Developer overview
│   ├── building/
│   │   ├── index.md                  # Building overview
│   │   ├── iso-build.md              # ISO building guide
│   │   └── release-process.md        # Release workflow
│   └── testing/
│       ├── index.md                  # Testing overview
│       ├── container-testing.md      # Container testing
│       └── manual-testing.md         # Manual testing guide
│
├── archive/                          # Historical/test reports (not in TOC)
│
└── _static/                          # Static assets
    ├── css/custom.css
    └── logo.png
```

### Build Commands

The documentation system uses **pixi** for dependency management (replaced Python venv for 2-3x faster builds).

**Prerequisites:**
```bash
# One-time pixi installation
curl -fsSL https://pixi.sh/install.sh | bash
# Restart shell or: source ~/.bashrc
```

**Local Development:**
```bash
# Install dependencies (one-time setup, ~40s first time, ~5s cached)
just docs-install

# Build documentation (~20s first build, ~8s cached)
just docs-build

# Serve with auto-reload (opens browser on http://localhost:3000)
just docs-serve

# Clean build artifacts
just docs-clean

# Full rebuild (clean + build)
just docs-rebuild
```

**Manual pixi commands** (if not using Justfile):
```bash
pixi install              # Install dependencies
pixi run docs-build       # Build documentation
pixi run docs-serve       # Serve with auto-reload
pixi run docs-clean       # Clean artifacts
```

**Output location:** `docs/_build/html/index.html`

### MyST Markdown Features and Examples

MyST (Markedly Structured Text) extends standard markdown with powerful features. **Use these extensively** in documentation.

#### Admonitions (Note/Tip/Warning/Danger Boxes)

```markdown
:::{note}
This is a note admonition. Use for supplementary information.
:::

:::{tip}
This is a tip. Use for helpful suggestions.
:::

:::{warning}
This is a warning. Use for important cautions.
:::

:::{danger}
This is a danger box. Use for critical warnings.
:::
```

#### Tabbed Content (Platform-Specific Instructions)

```markdown
::::{tab-set}

:::{tab-item} Linux
```bash
sudo dnf install package
```
:::

:::{tab-item} macOS
```bash
brew install package
```
:::

:::{tab-item} Windows
```powershell
choco install package
```
:::

::::
```

#### Collapsible Dropdowns

```markdown
:::{dropdown} Click to expand
This content is hidden until user clicks the dropdown.

Useful for long sections, optional details, or troubleshooting steps.
:::
```

#### Grids and Cards (Navigation Layouts)

```markdown
::::{grid} 2
:gutter: 3

:::{grid-item-card} User Guide
:link: user-guide/index
:link-type: doc

Learn how to use Bazzite AI
:::

:::{grid-item-card} Developer Guide
:link: developer-guide/index
:link-type: doc

Build and contribute to Bazzite AI
:::

::::
```

#### Cross-References Between Pages

```markdown
<!-- Reference another document (no .md extension) -->
See {doc}`user-guide/containers/usage` for container usage.

<!-- Reference a section heading -->
See {ref}`installation-guide` for setup instructions.

<!-- In the target document, mark the section: -->
(installation-guide)=
## Installation Guide
```

#### Code Blocks with Syntax Highlighting

```markdown
```python
def hello_world():
    print("Hello, World!")
```
```

Supported languages: python, bash, yaml, json, dockerfile, and 100+ more.

#### Definition Lists (Glossaries)

```markdown
Term 1
: Definition of term 1

Term 2
: Definition of term 2
: Can have multiple paragraphs
```

#### Badges and Labels

```markdown
{bdg-primary}`Primary`
{bdg-success}`Success`
{bdg-warning}`Warning`
{bdg-danger}`Danger`
{bdg-info}`Info`
```

#### Margin Notes (Side Comments)

```markdown
```{margin} Side note
This appears in the right margin for additional context.
```
```

### GitHub Pages Auto-Deployment

Documentation automatically builds and deploys on every push to main branch that affects:
- `docs/**` (any documentation file)
- `pixi.toml` (dependency changes)
- `pixi.lock` (locked dependency versions)
- `.github/workflows/docs.yml` (workflow changes)

**Workflow:** `.github/workflows/docs.yml`
- Uses `prefix-dev/setup-pixi@v0.8.1` for fast, cached pixi installation
- Builds with `pixi run docs-build`
- Deploys to GitHub Pages automatically
- **Build time:** ~18-30 seconds in CI (with cache)

**Manual Trigger:**
```bash
# Trigger workflow manually (requires gh CLI)
gh workflow run docs.yml
```

**View Build Status:**
- GitHub Actions tab in repository
- Check run status: https://github.com/atrawog/bazzite-ai/actions/workflows/docs.yml

### Adding New Documentation Pages

**Step-by-step workflow:**

1. **Create the markdown file in appropriate section:**
   ```bash
   # Example: Adding new container guide
   touch docs/user-guide/containers/advanced-usage.md
   ```

2. **Write content using MyST Markdown:**
   ```markdown
   # Advanced Container Usage

   :::{note}
   This guide covers advanced container topics.
   :::

   ## Custom Configurations

   See {doc}`usage` for basic container usage.

   ::::{tab-set}
   :::{tab-item} Podman
   Advanced podman configuration...
   :::
   :::{tab-item} Docker
   Advanced docker configuration...
   :::
   ::::
   ```

3. **Add to table of contents (`docs/_toc.yml`):**
   ```yaml
   - file: user-guide/index
     sections:
     - file: user-guide/containers/index
       sections:
       - file: user-guide/containers/usage
       - file: user-guide/containers/advanced-usage  # NEW
       - file: user-guide/containers/gpu-setup
   ```

4. **Test locally:**
   ```bash
   just docs-build    # Check for errors
   just docs-serve    # Preview in browser
   ```

5. **Commit and push:**
   ```bash
   git add docs/user-guide/containers/advanced-usage.md docs/_toc.yml
   git commit -m "Docs: Add advanced container usage guide"
   git push origin main
   ```

6. **Verify deployment:**
   - GitHub Actions builds automatically
   - Check https://atrawog.github.io/bazzite-ai/ after ~1-2 minutes

### Updating Existing Documentation

**Workflow for documentation updates:**

1. **Edit the markdown file**
2. **Test with live reload:**
   ```bash
   just docs-serve
   # Opens http://localhost:8000
   # Auto-reloads on file changes
   ```
3. **Commit and push** (auto-deploys)

**No rebuild needed** - Jupyter Book watches for changes during `docs-serve`.

### Documentation Dependencies

Dependencies are managed in `pixi.toml` (repository root):

```toml
[workspace]
name = "bazzite-ai-docs"
channels = ["conda-forge"]
platforms = ["linux-64"]

[dependencies]
python = ">=3.11,<3.12"
# Sphinx extensions from conda-forge
myst-parser = ">=2.0.0"
pydata-sphinx-theme = ">=0.15.0"
sphinx = ">=7.0.0"
sphinx-design = ">=0.5.0"          # Grids, cards, tabs, dropdowns
sphinx-copybutton = ">=0.5.0"      # Copy button for code blocks
sphinx-sitemap = ">=2.5.0"         # SEO sitemap generation
sphinx-autobuild = ">=2024.0.0"    # Auto-reload for development
sphinx-tabs = ">=3.4.0"            # Tabbed content
sphinxcontrib-mermaid = ">=0.9"    # Mermaid diagrams

[pypi-dependencies]
# Jupyter Book 2.x pre-release only available via PyPI (currently 2.0.0-b3)
jupyter-book = ">=2.0.0b0,<3.0"
```

**Note:** `docs/requirements.txt` is DEPRECATED (kept for reference only). All dependencies are now in `pixi.toml`.

**Important:** Jupyter Book 2.0 is a pre-release version (beta 3) only available via PyPI. It will move to conda-forge once it reaches stable release.

### Performance Improvements (Pixi Migration)

Migration from Python venv to pixi (completed 2025-01):

| Operation | Before (venv) | After (pixi) | Improvement |
|-----------|---------------|--------------|-------------|
| First install | ~60s | ~40s | 33% faster |
| Cached install | N/A | ~5s | Instant |
| First build | ~30s | ~20s | 33% faster |
| Cached build | ~15s | ~8s | 47% faster |
| CI/CD build | ~90s | ~45s | 50% faster |

**Key benefits:**
- ✅ 2-3x faster builds with better caching
- ✅ Exact reproducibility via `pixi.lock`
- ✅ No manual venv management
- ✅ Cross-platform consistency
- ✅ Simpler workflow (no activation needed)

### Troubleshooting Documentation Builds

**Build fails with syntax errors:**
```bash
just docs-build
# Check error output for line numbers
# Common issues:
# - Unclosed directives (missing :::)
# - Invalid cross-references ({doc}path/to/missing)
# - Broken YAML in _toc.yml
```

**GitHub Actions workflow fails:**
1. Check workflow logs: https://github.com/atrawog/bazzite-ai/actions
2. Common issues:
   - Path errors (ensure files at repo root, not in bazzite-ai/ subdirectory)
   - Pixi version mismatch (use `pixi-version: latest`)
   - Missing files in `docs/_toc.yml`

**Links not working:**
```markdown
<!-- ✅ Correct internal links -->
{doc}`path/to/file`           # No .md extension
{ref}`section-label`          # Reference labeled sections

<!-- ❌ Wrong -->
[Link](path/to/file.md)       # Standard markdown, no validation
```

**Pages not appearing in navigation:**
```yaml
# Must add to docs/_toc.yml
- file: path/to/new-page
```

**Auto-reload not working:**
```bash
# Kill any existing servers
pkill -f sphinx-autobuild

# Restart
just docs-serve
```

### Documentation Best Practices

1. **Start with structure** - Create section index.md files first
2. **Use MyST features liberally** - Tabs, admonitions, grids make content more engaging
3. **Cross-reference extensively** - Link related pages with {doc} and {ref}
4. **Test locally always** - Never commit without building first
5. **Write for your audience** - User guide vs developer guide have different tones
6. **Keep TOC organized** - Logical hierarchy aids navigation
7. **Add visual breaks** - Use admonitions, dropdowns, grids to break up long text
8. **Version-specific info** - Use admonitions to highlight version requirements

### Archive vs Main Documentation

- **Main documentation** (`docs/*/index.md`, etc.): Current, actively maintained content
  - Appears in `_toc.yml` navigation
  - Updated regularly
  - Versioned with releases

- **Archive** (`docs/archive/`): Historical reference, test reports, one-time fixes
  - NOT in `_toc.yml` (won't appear in navigation)
  - Searchable via full-text search
  - Preserved for historical context

**When to archive:**
- Test reports from specific releases
- One-time migration documentation
- Deprecated feature documentation
- Historical design decisions

## Testing ujust Command Changes Locally

When developing ujust recipes in `system_files/usr/share/ublue-os/just/`, you can test changes locally without rebuilding the entire container image. This dramatically speeds up the development cycle from hours to seconds.

### The Problem

Bazzite AI is an **immutable OS** - the `/usr/` directory is read-only. Changes to justfiles in `system_files/` only take effect after:
1. Building a new container image (~6-8 minutes)
2. Pushing to registry
3. Rebasing system to new image
4. Rebooting

This workflow is impractical for iterative development.

### Quick Reference

| Method | Speed | Risk | Reboot Required | Best For |
|--------|-------|------|-----------------|----------|
| **Test Wrapper** | ⚡ Instant | ✅ None | ❌ No | Quick syntax/logic checks |
| **rpm-ostree usroverlay** | 🐢 Medium | ⚠️ Low | ✅ Yes (to undo) | Full environment testing |
| **Symlink Overlay** | 🐢 Medium | ⚠️ Low | ✅ Yes (to undo) | Iterative development |
| **Direct just -f** | ⚡ Instant | ✅ None | ❌ No | Single recipe testing |

### Method 1: Test Wrapper (Recommended)

**Use when:** You need quick feedback on recipe changes without system modifications.

The test wrapper (`testing/ujust-test`) uses repository justfiles instead of system files.

**Usage:**

```bash
# List available test recipes
./testing/ujust-test --list

# Test a specific recipe
./testing/ujust-test install-devcontainers-cli

# Test with arguments
./testing/ujust-test --help
```

**How it works:**
1. Wrapper script sets `--justfile` to `testing/test-master.justfile`
2. Test justfile imports recipes from `system_files/usr/share/ublue-os/just/`
3. Recipes execute using repository code (not system files)

**Pros:**
- ✅ No system modifications
- ✅ No reboot required
- ✅ Safe for experimentation
- ✅ Instant feedback

**Cons:**
- ⚠️ May not have full system dependencies (e.g., `/usr/lib/ujust/ujust.sh`)
- ⚠️ Some recipes might behave differently than in production

**Example:**
```bash
# Edit a justfile
vim system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just

# Test immediately
./testing/ujust-test install-devcontainers-cli

# If it works, commit
git add system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just
git commit -m "Fix: devcontainers-cli verification check"
```

### Method 2: rpm-ostree usroverlay (Full Environment)

**Use when:** You need to test in the actual system environment with all dependencies.

**⚠️ WARNING:** Requires reboot to fully undo, even with `--transient` mode.

**Usage:**

```bash
# Step 1: Apply usroverlay and copy files (requires root)
sudo ./testing/apply-usroverlay.sh --transient

# Step 2: Test with real ujust command
ujust install-devcontainers-cli
ujust install-dev-tools

# Step 3: Reboot to undo changes
sudo systemctl reboot
```

**How it works:**
1. `rpm-ostree usroverlay --transient` makes `/usr/` temporarily writable
2. Script backs up original files to `/var/tmp/bazzite-ai-just-backup-*/`
3. Copies modified justfiles from repository to `/usr/share/ublue-os/just/`
4. You test with normal `ujust` commands
5. Reboot restores immutability and reverts changes

**Modes:**
- `--transient` (default): Changes lost on reboot
- `--hotfix`: Changes persist across reboots (use with caution)

**Pros:**
- ✅ Full system integration
- ✅ Tests with real ujust command
- ✅ Same environment as production
- ✅ All dependencies available

**Cons:**
- ⚠️ Requires root access
- ⚠️ Requires reboot to fully undo
- ⚠️ More invasive than wrapper method
- ⚠️ Automatic backups in `/var/tmp/`

**Safety:**
- Backups are created automatically before copying files
- Use `--transient` for testing (changes revert on reboot)
- Use `--hotfix` only if you understand the implications

### Method 3: Symlink Overlay (Development Workflow)

**Use when:** You're doing iterative development and want live changes.

This combines usroverlay with symlinks for a live-editing workflow.

```bash
# Step 1: Apply usroverlay
sudo rpm-ostree usroverlay --transient

# Step 2: Backup and create symlinks manually
sudo cp /usr/share/ublue-os/just/97-bazzite-ai-dev.just \
        /var/tmp/97-bazzite-ai-dev.just.backup

sudo ln -sf /var/home/atrawog/Repo/bazzite-ai/bazzite-ai/system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just \
            /usr/share/ublue-os/just/97-bazzite-ai-dev.just

# Step 3: Edit in repo, test immediately
vim system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just
ujust install-devcontainers-cli  # Uses live repository file

# Step 4: Reboot when done
sudo systemctl reboot
```

**Pros:**
- ✅ Live editing: changes immediately testable
- ✅ Full system integration
- ✅ Best for multiple test iterations

**Cons:**
- ⚠️ Requires manual symlink creation
- ⚠️ Requires reboot to undo
- ⚠️ Easy to forget what's been modified

### Method 4: Direct just Command (Single Recipe)

**Use when:** Testing specific recipe logic in isolation.

```bash
# Create a standalone test file
cat > /tmp/test.justfile << 'EOF'
test-recipe:
    #!/usr/bin/bash
    echo "Testing recipe logic..."
    # Your recipe code here
EOF

# Test it
just -f /tmp/test.justfile test-recipe
```

**Pros:**
- ✅ Fastest for isolated testing
- ✅ No system modifications
- ✅ Good for debugging recipe logic

**Cons:**
- ⚠️ Doesn't test imports/integration
- ⚠️ Doesn't test system dependencies

### Real-World Example: Testing devcontainers-cli Fix

This example shows how we used these methods to test the devcontainers-cli fix (commit ba102ca):

**Problem:** `install-devcontainers-cli` showed false "Installation failed" error

**Testing Workflow:**

1. **Initial Discovery** (without testing tools):
   - Edited `system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just`
   - Tried to test → realized system files are immutable
   - Had to commit and wait for CI build (~8 minutes)

2. **With Test Wrapper** (after creating tools):
   ```bash
   # Edit the fix
   vim system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just

   # Add: export PATH="$HOME/.npm-global/bin:$PATH" before verification

   # Test immediately
   ./testing/ujust-test install-devcontainers-cli
   # ✓ Verified: No syntax errors, logic looks correct
   ```

3. **With usroverlay** (full validation):
   ```bash
   sudo ./testing/apply-usroverlay.sh --transient

   # Test with real environment
   ujust install-devcontainers-cli
   # ✓ Verified: Works with actual npm, PATH updates correctly

   # Reboot to clean up
   sudo systemctl reboot
   ```

4. **Commit and Deploy:**
   ```bash
   git add system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just
   git commit -m "Fix: devcontainers-cli false installation error"
   git push  # Triggers CI/CD
   ```

**Time Saved:**
- Without tools: 10+ minutes per iteration (full build + test)
- With test wrapper: <10 seconds per iteration
- **Result:** 60x faster development cycle!

### Testing Utilities Location

All testing utilities are in the `testing/` directory:

```
testing/
├── ujust-test              # Test wrapper script
├── test-master.justfile    # Test justfile with imports
├── apply-usroverlay.sh     # usroverlay helper script
└── README.md               # Detailed testing documentation
```

See `testing/README.md` for complete usage instructions and troubleshooting.

### Best Practices

1. **Always test with wrapper first** before using usroverlay
2. **Use `--transient` mode** for usroverlay testing (safer)
3. **Commit working changes immediately** before trying usroverlay
4. **Document your testing process** for future reference
5. **Verify in full build** before deploying to production

### Common Pitfalls

❌ **Don't:** Edit system files directly with usroverlay without backing up
✅ **Do:** Use `apply-usroverlay.sh` which creates automatic backups

❌ **Don't:** Use `--hotfix` mode unless you know what you're doing
✅ **Do:** Use `--transient` mode for testing (changes revert on reboot)

❌ **Don't:** Forget you have usroverlay active
✅ **Do:** Reboot promptly after testing to restore immutability

❌ **Don't:** Skip wrapper testing and go straight to usroverlay
✅ **Do:** Test incrementally: wrapper → usroverlay → full build

### Troubleshooting

**Test wrapper says "Could not find source file for import":**
```bash
# Check that justfiles exist in repo
ls -l system_files/usr/share/ublue-os/just/9*.just

# Verify test-master.justfile imports
cat testing/test-master.justfile | grep import
```

**usroverlay script fails with "must be run as root":**
```bash
# Use sudo
sudo ./testing/apply-usroverlay.sh --transient
```

**Changes not taking effect after usroverlay:**
```bash
# Verify files were copied
ls -l /usr/share/ublue-os/just/9*.just
cat /usr/share/ublue-os/just/97-bazzite-ai-dev.just | grep "export PATH"
```

**Want to undo usroverlay without rebooting:**
```bash
# Restore from backup
sudo cp /var/tmp/bazzite-ai-just-backup-*/* /usr/share/ublue-os/just/

# Note: Full immutability only restored after reboot
```

## Release Management and ISO Distribution

This project includes a comprehensive workflow for building ISO installers and distributing them via BitTorrent (due to GitHub's 2GB file size limit).

### Release Directory Structure

```
releases/
├── 42.20251022/              # Version-specific directory
│   ├── bazzite-ai-42.20251022.iso
│   ├── bazzite-ai-nvidia-42.20251022.iso
│   ├── bazzite-ai-42.20251022.iso.torrent
│   ├── bazzite-ai-nvidia-42.20251022.iso.torrent
│   ├── SHA256SUMS
│   └── 42.20251022-magnets.txt
└── latest -> 42.20251022     # Symlink to current release
```

### Complete Release Workflow

#### Quick Start (Fresh ISO Build)

```bash
# 1. Check prerequisites
just release-check-prereqs

# 2. Check current status (optional)
just release-status

# 3. Run complete release workflow (90-150 min)
just release

# 4. Monitor seeding status
just release-seed-status
```

The `just release` command automates the entire release process:

```bash
# Full automated release (8 steps, 90-150 minutes)
just release [tag]

# Steps performed:
# 0. Check prerequisites (tools, authentication, disk space)
# 1. Pull container images from GHCR (tag or :latest)
# 2. Build both ISO variants (60-120 min total)
# 3. Generate SHA256 checksums
# 4. Organize files into releases/{tag}/ directory
# 5. Create .torrent files with public trackers
# 6. Verify torrents are valid
# 7. Start seeding service (if configured)
# 8. Create GitHub release with torrents and magnet links
```

**Important Notes:**
- ISOs are built **fresh** from the latest container images
- Each ISO takes 30-60 minutes to build (2 ISOs = 60-120 min total)
- Requires ~20GB disk space for ISOs
- GitHub CLI must be authenticated: `gh auth login`
- Seeding service is optional but recommended

#### Helper Commands

**Prerequisites and Status:**
```bash
# Check all prerequisites before starting
just release-check-prereqs

# Show current release status
just release-status [tag]

# Show installation instructions for tools
just release-install-tools
```

### Individual Release Commands

**ISO Building:**
```bash
# Pull container images from registry
just release-pull [tag]

# Build both ISO variants
just release-build-isos [tag]

# Generate and verify checksums
just release-checksums
```

**File Organization:**
```bash
# Organize release files into releases/{tag}/ structure
just release-organize [tag]

# Creates:
# - releases/{tag}/ directory
# - Moves ISOs, torrents, checksums into it
# - Updates releases/latest symlink
```

**Torrent Distribution:**
```bash
# Create .torrent files with public trackers
just release-create-torrents [tag]

# Display torrent info and magnet links
just release-torrents-info [tag]
```

**Seeding Management:**
```bash
# Set up transmission-daemon systemd service
just release-setup-seeding

# Start seeding torrents (adds to transmission-daemon)
just release-seed-start [tag]

# Stop seeding service
just release-seed-stop

# Show seeding status and statistics
just release-seed-status
```

The seeding service:
- Runs as a systemd user service (`bazzite-ai-seeding.service`)
- Uses transmission-daemon for BitTorrent
- Configured with 2.0 ratio limit (seeds to 200% uploaded)
- Continues seeding across reboots
- Configuration: `.transmission-daemon.json` (git-ignored)

**GitHub Release:**
```bash
# Create GitHub release with torrent files
just release-create [tag]

# Uploads:
# - .torrent files (small enough for GitHub)
# - SHA256SUMS
# - Magnet links in release notes
# - Instructions for downloading via BitTorrent
```

**Utilities:**
```bash
# List all releases
just release-list

# Clean release artifacts (prompts for confirmation)
just release-clean

# Verify checksums
just release-verify

# Upload files to existing release
just release-upload [tag] [files...]
```

### Why BitTorrent Distribution?

ISOs are 8+ GB each, exceeding GitHub's 2GB release asset limit. BitTorrent provides:
- **Scalability**: Distributed bandwidth from seeders
- **Reliability**: Resume interrupted downloads
- **Verification**: Built-in integrity checking
- **Cost**: No hosting fees or bandwidth limits

Users can download via:
1. `.torrent` files from GitHub releases
2. Magnet links (in release notes)
3. Any BitTorrent client (Transmission, qBittorrent, Deluge)

## Image Variants

Bazzite AI builds **1 unified KDE Plasma variant** (GNOME is not supported):

- **bazzite-ai** - KDE Plasma unified image (from `bazzite-nvidia-open`)
  - Based on bazzite-nvidia-open with open NVIDIA drivers (works on all GPUs: AMD/Intel/NVIDIA)
  - nvidia-container-toolkit pre-installed for GPU container support
  - Single image for simplified maintenance and user experience

⚠️ **Note**: Only KDE variant is officially supported. Any GNOME builds in CI are experimental/unofficial.

## Container Variants

Bazzite AI provides two development container images for isolated development, built from a **unified multi-stage Containerfile** for maximum layer reuse and parallel builds.

**Unified Architecture (Containerfile.containers):**
- **Stage 1 (common-base)**: Shared foundation with Fedora 42 + all development tools
- **Stage 2a (base-container)**: CPU-only variant (`--target=base-container`)
- **Stage 2b (nvidia-additions)**: Adds cuDNN, TensorRT (built in parallel with 2a)
- **Stage 3 (nvidia-container)**: GPU variant (`--target=nvidia-container`)

**Benefits:**
- 40-60% faster parallel builds in CI (no sequential dependency)
- Maximum layer reuse via shared common-base stage
- Single source of truth (one Containerfile)
- Efficient incremental builds

### bazzite-ai-container (Base)

**CPU-only development container** - Clean base image with no NVIDIA/CUDA dependencies.

**Purpose:**
- Safe isolated environment for Claude Code with `--dangerously-skip-permissions`
- CPU-only development and testing
- Lightweight for systems without GPUs
- No systemd overhead - pure tooling

**Key Features:**
- **Clean Separation**: No CUDA/NVIDIA references
- **Smaller Size**: No ML libraries overhead
- **Pre-built Images**: Always uses latest from GitHub Container Registry
- **Base**: Fedora 42 with all development tools
- **VS Code**: Native Dev Containers support

**Justfile Commands:**
```bash
just pull-container [tag]       # Pull from GHCR
just build-container [tag]      # Build locally
just run-container [tag]        # Run interactively
```

### bazzite-ai-container-nvidia (NVIDIA)

**GPU-accelerated development container** - Builds on base, adds cuDNN and TensorRT.

**Purpose:**
- CUDA-accelerated AI/ML workflows
- GPU development and testing
- Includes optimized ML libraries (cuDNN, TensorRT)
- Works with host CUDA runtime via nvidia-container-toolkit

**Key Features:**
- **Built on Base**: Layered architecture for efficient builds
- **ML Libraries**: cuDNN and TensorRT pre-installed
- **Host Passthrough**: Uses host CUDA runtime (no toolkit in container)
- **Pre-built Images**: Always uses latest from GitHub Container Registry
- **VS Code**: Native Dev Containers support

**Host Requirements:**
1. Must use **bazzite-ai** (KDE only)
2. nvidia-container-toolkit (pre-installed)
3. CDI config via `ujust setup-gpu-containers`

See `docs/HOST-SETUP-GPU.md` and `docs/CONTAINER.md`.

**Justfile Commands:**
```bash
just pull-container-nvidia [tag]       # Pull from GHCR
just build-container-nvidia [tag]      # Build locally (requires base)
just run-container-nvidia [tag]        # Run with GPU
just test-cuda-container [tag]         # Test CUDA/GPU
```

### VS Code Usage

**For GPU Development:**
1. Install Dev Containers extension
2. Open repo in VS Code
3. Command Palette → "Reopen in Container"
4. Uses `.devcontainer/devcontainer.json` (NVIDIA variant)

**For CPU-Only Development:**
1. Open `.devcontainer/devcontainer-base.json` in VS Code
2. Command Palette → "Dev Containers: Reopen in Container"
3. Select "devcontainer-base" configuration

The configurations pull the latest images from GHCR automatically. To update, rebuild the container.

See `docs/CONTAINER.md`.

### ujust Commands

On bazzite-ai (KDE):

```bash
ujust setup-gpu-containers  # One-time GPU setup (nvidia-container-toolkit pre-installed)
```

## Key Modifications from Base Bazzite

Developer-focused changes for **KDE Plasma variants** in `build_files/20-install-apps.sh`:

1. **Removed Gaming Defaults**:
   - Disabled autologin to Steam Game Mode
   - Removed SDDM steamos configs
   - Re-enabled SDDM login screens (KDE)
   - Re-enabled user switching and lock screen in KDE

2. **Added Developer Tools**:
   - VS Code (from Microsoft repo)
   - Docker CE + docker-compose
   - BPF tools (bpftrace, bpftop, bcc)
   - Container tools (podman-machine, podman-tui)
   - **nvidia-container-toolkit** (always installed for GPU container support)
   - Android tools (android-tools, usbmuxd)
   - Cloud tools (restic, rclone)
   - Development utilities (ccache, flatpak-builder, qemu-kvm)
   - Python ramalama for LLM deployment

3. **Enabled Services**:
   - input-remapper (for device remapping)
   - uupd.timer (Universal Blue update manager)
   - ublue-setup-services (first-boot setup)

## Configuration Files

**Container Build:**
- `Containerfile` - Multi-stage build using BASE_IMAGE arg
- `image-versions.yaml` - Tracks base image versions/digests (managed by Renovate)
- `artifacthub-repo.yml` - ArtifactHub metadata for image discovery

**External Repositories:**
- `vscode` - Microsoft repository for VS Code
- `docker-ce-stable` - Docker CE repository
- `copr:codifryed:CoolerControl` - CoolerControl COPR (hardware monitoring for AIOs/fan hubs)
- `copr:scottames:ghostty` - Ghostty terminal COPR
- All external repos disabled by default, enabled only during installation
- .NET SDK 9.0 available in standard Fedora 42 repos (no external repo needed)

**ISO/VM Images:**
- `image.toml` - Minimal config for VM/raw images (20GB root partition)
- `iso.toml` - Unified ISO installer config with kickstart to switch to registry image

**Release Infrastructure:**
- `releases/` - Directory structure for organized release artifacts (git-ignored)
- `.transmission-daemon.json` - Torrent seeding daemon config (git-ignored)
- `scripts/setup-seeding-service.sh` - Sets up systemd seeding service
- `scripts/create-release.sh` - Automated release creation script

**Container Variants:**
- `Containerfile.containers` - Unified multi-stage build for both CPU and GPU variants
  - Stage 1 (common-base): Shared Fedora 42 + all dev tools
  - Stage 2a (base-container): CPU-only final stage
  - Stage 2b (nvidia-additions): NVIDIA ML libraries layer
  - Stage 3 (nvidia-container): GPU final stage
- `.devcontainer/devcontainer.json` - VS Code configuration for NVIDIA variant
- `.devcontainer/devcontainer-base.json` - VS Code configuration for base variant (CPU-only)
- `build_files/devcontainer/install-devcontainer-tools.sh` - Base tool installation (referenced in common-base)
- `build_files/container-nvidia/install-nvidia-tools.sh` - NVIDIA ML libraries (referenced in nvidia-additions)
- `docs/CONTAINER.md` - Container usage guide
- `docs/HOST-SETUP-GPU.md` - GPU setup (nvidia variant)
- **Note:** Legacy `Containerfile.container` and `Containerfile.container-nvidia` deprecated in favor of unified build

**Build Optimizations:**
- `.dockerignore` - Excludes unnecessary files from build context (docs, releases, git)
  - Reduces context size for faster uploads to buildah
  - Improves cache hit rates by excluding volatile files

**Documentation System:**
- `pixi.toml` - Pixi workspace configuration with documentation dependencies
- `pixi.lock` - Locked dependency versions (committed for reproducibility)
- `docs/myst.yml` - Jupyter Book 2.0 unified configuration (replaces _config.yml + _toc.yml)
- `docs/requirements.txt` - DEPRECATED (use pixi.toml instead)
- `docs/_static/css/custom.css` - Custom styling
- `.github/workflows/docs.yml` - GitHub Pages auto-deployment workflow (updated for JB 2.0)
- `DOCS-MIGRATION-SUMMARY.md` - Documentation migration and pixi migration details

**Developer Documentation:**
- `docs/ISO-BUILD.md` - Comprehensive ISO building guide
- `CLAUDE.md` - This file, guidance for Claude Code
- `docs/CONTAINER.md` - Container usage guide
- `docs/HOST-SETUP-GPU.md` - GPU setup guide

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/build.yml`):
1. Checks out code and sets up BTRFS storage
2. **Build Optimizations:**
   - **Buildah Registry Cache**: Simplified single-tier caching for maximum compatibility
     - Remote layer cache stored in GHCR (`ghcr.io/atrawog/bazzite-ai-buildcache`)
     - Separate caches for OS (`bazzite-ai-buildcache`) and containers (`bazzite-ai-container-buildcache`, `bazzite-ai-container-nvidia-buildcache`)
     - Configured via `--cache-from` and `--cache-to` flags
     - Only pushes cache on main branch to save bandwidth
     - No cache mounts or bind mounts - ensures buildah can query external registry cache
   - **Architecture Philosophy**:
     - Prioritizes cache compatibility over micro-optimizations
     - Direct file copies instead of bind mounts
     - Explicit cleanup (`dnf5 clean all`) within layers instead of cache mounts
     - Simpler build process = better cache hit rates for RUN commands
   - **Performance Profile**:
     - First build: ~6-8 minutes (builds all layers, populates cache)
     - Incremental config changes: **~30-60 seconds** (when cache works correctly)
     - Incremental package changes: **~4-5 minutes** (when cache works correctly)
     - Trade-off: Lose 20-40s from DNF5 cache, gain 5-7 min from proper layer caching
   - **.dockerignore**: Reduces build context size by excluding unnecessary files
3. Fetches base image version from upstream Bazzite (**using `:stable` tag**)
   - **Why stable, not latest?** Stable tag ensures production-ready builds, better cache reuse (40-60% fewer invalidations), and more predictable behavior
   - Stable updates every 3-7 days vs latest's potential daily changes
   - Both currently point to same version (42.20251019) but serve different purposes
4. Builds unified KDE OS image using buildah (bazzite-ai from bazzite-nvidia-open:stable base)
5. **Builds container images in parallel using matrix strategy:**
   - `build_containers` matrix job with 2 variants:
     - `base`: Builds bazzite-ai-container with `--target=base-container`
     - `nvidia`: Builds bazzite-ai-container-nvidia with `--target=nvidia-container`
   - Both variants share buildah cache for common-base stage
   - No sequential dependency - 40-60% faster than previous architecture
6. Tags with multiple patterns (latest, stable, stable-{version}, {version}.{date})
7. Pushes to ghcr.io/atrawog/bazzite-ai, ghcr.io/atrawog/bazzite-ai-container*
8. Signs all images with cosign (using SIGNING_SECRET)

## End-User Commands

Users of the built image can run these ujust commands. These are organized into 4 category files that integrate with bazzite's command structure:

- **95-bazzite-ai-system.just** - System configuration and service management (`[group("system")]`, `[group("network")]`)
- **96-bazzite-ai-apps.just** - Application installation (`[group("apps")]`)
- **97-bazzite-ai-dev.just** - Development tools (`[group("development")]`)
- **98-bazzite-ai-virt.just** - Virtualization and containers (`[group("virtualization")]`)

Commands appear grouped by function when running `ujust --list`, mixed naturally with bazzite's upstream commands.

### Flatpak Management (38 total flatpaks)
```bash
# Install all flatpaks at once
ujust install-flatpaks-all

# Or install by category:
ujust install-flatpaks-dev             # Development tools (8 apps)
ujust install-flatpaks-media           # Media & graphics (9 apps)
ujust install-flatpaks-gaming          # Gaming tools (4 apps)
ujust install-flatpaks-communication   # Chat apps (3 apps)
ujust install-flatpaks-productivity    # Browsers & office (7 apps)
ujust install-flatpaks-utilities       # Remote & download tools (5 apps)
ujust install-flatpaks-experimental    # Experimental apps (2 apps)
```

### Development Tools
```bash
# Install pixi package manager (user home directory)
ujust install-pixi

# Install devcontainers CLI (user home directory)
ujust install-devcontainers-cli

# Install both pixi and devcontainers CLI
ujust install-dev-tools

# Install LM Studio (local LLM runtime)
ujust install-lmstudio

# Check LM Studio installation and service status
ujust check-lmstudio

# Toggle LM Studio GUI mode (full application)
ujust toggle-lmstudio-gui [enable|disable|status|help]

# Toggle LM Studio server mode (API only, more efficient)
ujust toggle-lmstudio-server [enable|disable|status|help]
```

### System Configuration
```bash
# Install extra fonts via Homebrew
ujust install-fonts

# Toggle between Steam Game Mode and Desktop session on boot (KDE only)
ujust toggle-gamemode [gamemode|desktop|status|help]

# Setup GPU access for containers (bazzite-ai-nvidia KDE only)
ujust setup-gpu-containers

# Install Claude Code CLI (user home directory)
ujust install-claude-code

# Check Claude Code installation and version
ujust check-claude-code

# Enable passwordless sudo for wheel group (single-user dev systems only)
ujust enable-passwordless-sudo

# Disable passwordless sudo (restore password requirement)
ujust disable-passwordless-sudo

# Toggle SSH server (enable/disable at boot)
ujust toggle-sshd [enable|disable|status|help]

# Toggle Docker daemon (always-on vs socket-activated)
ujust toggle-docker [enable|disable|status|help]

# Toggle Syncthing user service (enable/disable at boot)
ujust toggle-syncthing [enable|disable|status|help]
```

## Important Notes

- **KDE Only**: Bazzite AI only supports KDE Plasma variants, not GNOME.
- **NVIDIA Variant**: GPU container support requires bazzite-ai-nvidia (KDE).
- **Immutable Base**: This builds an immutable OS. Changes go in `build_files/` scripts or `system_files/` configs.
- **Rootful Podman**: VM/ISO builds require rootful podman access (sudo).
- **Podman Preferred**: The justfile auto-detects podman or docker, preferring podman.
- **No Direct Installation**: Users rebase existing Bazzite installs using `rpm-ostree rebase`.
- **Derived from Bazzite Deck**: Uses `-deck` variants as base, then removes gaming-specific configs.
- **Release Directory**: `releases/` contains version-specific subdirectories with ISOs, torrents, and checksums. This directory is git-ignored.
- **BitTorrent Distribution**: ISOs exceed GitHub's 2GB limit, so they're distributed via BitTorrent. The seeding service uses transmission-daemon as a systemd user service.
- **ISO Build Time**: Each ISO variant takes 30-60 minutes to build. The complete release workflow takes 1-2 hours.
- **SSH Server**: sshd.service is enabled by default for remote access (port 22). Use `ujust toggle-sshd` to disable.
- **Docker Daemon**: Both docker.socket (on-demand) and docker.service (always-on) are enabled. Socket activation is more efficient. Use `ujust toggle-docker` to switch modes.
- **Documentation**: ALL .md files MUST be created in `docs/` directory using MyST Markdown syntax (exceptions: README.md, CLAUDE.md). Documentation auto-deploys to GitHub Pages on every push. See "Documentation System" section for details.
