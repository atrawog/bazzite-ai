---
title: Release Process
---

# Bazzite AI Release Process

Comprehensive guide for creating Bazzite AI releases with ISO builds, BitTorrent distribution, and GitHub releases.

## Overview

```{admonition} Release Components
:class: tip

A complete release involves:
1. Building fresh ISO installers from latest container images
2. Creating torrent files for BitTorrent distribution
3. Setting up seeding to distribute ISOs
4. Publishing the release on GitHub
```

**Time Estimate:** 90-150 minutes (mostly ISO build time)
**Disk Space Required:** ~20GB for ISOs
**Prerequisites:** GitHub CLI authentication, transmission tools

## Pre-Release Checklist

```{admonition} Verify before starting
:class: important

- [ ] Latest CI build succeeded on GitHub Actions
- [ ] Container images published to GHCR
- [ ] Prerequisites met: `just release-check-prereqs`
- [ ] Sufficient disk space (~20GB)
- [ ] GitHub CLI authenticated: `gh auth status`
- [ ] 2+ hours available for ISO builds
```

**Verify container images:**

```bash
# Check images exist
podman pull ghcr.io/atrawog/bazzite-ai:latest
```

## Quick Start

For a complete release with fresh ISOs:

```bash
# 1. Check prerequisites
just release-check-prereqs

# 2. Check current status
just release-status

# 3. Run complete release workflow (90-150 min)
just release

# 4. Monitor seeding status
just release-seed-status
```

## Detailed Step-by-Step Process

### Step 0: Verify Prerequisites

```bash
just release-check-prereqs
```

::::{dropdown} Checks performed
:open:

- ✓ Container runtime (podman/docker)
- ✓ GitHub CLI installed and authenticated
- ✓ Torrent creation tools (transmission-create)
- ✓ Torrent management tools (transmission-daemon, transmission-show)
- ✓ Sufficient disk space (~20GB)
- ✓ Seeding service setup (optional)

**If any checks fail:**
- Follow the instructions provided
- Install missing tools: `just release-install-tools`
- Authenticate GitHub CLI: `gh auth login`

::::

### Step 1: Pull Latest Container Images

```bash
just release-pull [tag]
```

**What it does:**
- Pulls images from GitHub Container Registry
- Tags them locally as `localhost/bazzite-ai:latest`
- Prepares images for ISO building

**Time:** ~5-10 minutes

### Step 2: Build Fresh ISOs

```bash
just release-build-isos [tag]
```

```{warning}
This is the longest step! Each ISO takes 30-60 minutes to build.
```

**What it does:**
- Checks if ISOs already exist (prompts to rebuild)
- Builds unified ISO from `localhost/bazzite-ai:latest`
- Moves built ISOs from `output/bootiso/` to root directory

**Output:** `bazzite-ai-{tag}.iso` (~8.2GB)

**Time:** 60-120 minutes total

### Step 3: Generate Checksums

```bash
just release-checksums
```

**What it does:**
- Generates `SHA256SUMS` file
- Verifies checksums immediately
- Displays checksums for review

**Output:**
```text
SHA256SUMS:
<hash>  bazzite-ai-42.20251023.iso
```

**Time:** < 1 minute

### Step 4: Organize Release Files

```bash
just release-organize [tag]
```

**What it does:**
- Creates `releases/{tag}/` directory
- Moves ISOs, torrents, and checksums
- Updates `releases/latest` symlink

**Directory structure:**

```
releases/
├── 42.20251023/
│   ├── bazzite-ai-42.20251023.iso
│   ├── SHA256SUMS
│   └── (torrents will be added here)
└── latest -> 42.20251023
```

**Time:** < 1 minute

### Step 5: Create Torrent Files

```bash
just release-create-torrents [tag]
```

**What it does:**
- Creates `.torrent` files for ISOs
- Uses 6 public trackers for open source distribution
- Generates magnet links in `{tag}-magnets.txt`

**Torrent Configuration:**

```{list-table}
:header-rows: 1
:widths: 30 70

* - Setting
  - Value
* - **Trackers**
  - 6 public trackers (opentrackr, stealth.si, etc.)
* - **Piece Size**
  - Automatic (optimal for 8GB files)
* - **Comment**
  - Includes project description
```

**Time:** ~2 minutes

### Step 6: Verify Torrents

```bash
just release-verify-torrents [tag]
```

**What it does:**
- Checks torrent files exist and are valid
- Verifies ISOs exist and match torrent metadata
- Ensures magnet links were generated correctly

**Time:** < 1 minute

### Step 7: Start Seeding

::::{tab-set}

:::{tab-item} First Time Setup

```bash
# Set up seeding service
just release-setup-seeding
```

This sets up transmission-daemon as a systemd user service.

:::

:::{tab-item} Start Seeding

```bash
# Add torrents to seeder
just release-seed-start [tag]
```

**What it does:**
- Starts the seeding service
- Adds torrent files to the seeder
- Begins uploading to peers

:::

::::

**Seeding Configuration:**

```{list-table}
:header-rows: 1
:widths: 30 70

* - Setting
  - Value
* - **Service**
  - systemd user service `bazzite-ai-seeding.service`
* - **Daemon**
  - transmission-daemon
* - **Ratio Limit**
  - 2.0 (seeds to 200% uploaded, then stops)
* - **Port**
  - 51413 (peer connections)
* - **RPC Port**
  - 9091 (localhost only, for control)
```

**Monitor seeding:**

```bash
just release-seed-status
```

**Time:** ~2 minutes

### Step 8: Create GitHub Release

```bash
just release-create [tag]
```

**What it does:**
- Checks if release already exists
- Uploads `.torrent` files (~50KB each)
- Uploads `SHA256SUMS` file
- Generates release notes with file sizes and magnet links

**Release Assets:**
- `bazzite-ai-{tag}.iso.torrent` (~50KB)
- `SHA256SUMS` (text file)

```{note}
ISO files are NOT uploaded to GitHub (they exceed the 2GB limit). Users download them via BitTorrent.
```

**Time:** ~1 minute

## One-Command Release

Run the entire workflow with a single command:

```bash
just release [tag]
```

This automatically runs all 8 steps in sequence with progress indicators.

## Post-Release Verification

### Check Release Status

```bash
just release-status [tag]
```

::::{dropdown} Verify all components
:open:

- ✓ Container images pulled
- ✓ ISOs exist with correct sizes
- ✓ Checksums generated
- ✓ Torrents created
- ✓ Seeding active
- ✓ GitHub release created

::::

### Verify Seeding

```bash
just release-seed-status
```

**Should show:**
- ✓ Service running
- ✓ Active torrents
- Upload/download statistics

### Test GitHub Release

```bash
gh release view [tag]
```

Or visit: `https://github.com/atrawog/bazzite-ai/releases/tag/{tag}`

::::{dropdown} Verify release page
:open:

- ✓ Release notes include file sizes
- ✓ Magnet links are present and formatted correctly
- ✓ .torrent files are downloadable
- ✓ SHA256SUMS is available

::::

### Test Torrent Download

Download a `.torrent` file and open it in a BitTorrent client to verify:
- ✓ Torrent loads correctly
- ✓ ISO file is recognized
- ✓ Download starts

## Seeding Management

### Start Seeding

```bash
just release-seed-start [tag]
```

### Check Seeding Status

```bash
just release-seed-status
```

**Shows:**
- Service status (running/stopped)
- Active torrents count
- Upload/download rates
- Ratio for each torrent

### Stop Seeding

```bash
just release-seed-stop
```

```{note}
Seeding stops automatically when torrents reach 2.0 ratio (200% uploaded).
```

### View Seeding Logs

```bash
journalctl --user -u bazzite-ai-seeding -f
```

## Troubleshooting

### ISO Build Failures

**Problem:** "No space left on device"

::::{dropdown} Solutions

```bash
# Check available space
df -h .

# Clean old artifacts
just release-clean
just sudo-clean

# Remove old releases if needed
rm -rf releases/old-tag/
```

::::

**Problem:** Container errors

::::{dropdown} Solutions

```bash
# Ensure images are pulled fresh
just release-pull [tag]

# Check if images exist
podman images | grep bazzite-ai

# Try rebuilding
just rebuild-iso
```

::::

### Torrent Creation Failures

**Problem:** "transmission-create: command not found"

::::{dropdown} Solutions

```bash
# Install transmission tools
sudo dnf install transmission-cli

# Or use the install helper
just release-install-tools
```

::::

### Seeding Not Working

**Problem:** Seeding service won't start

::::{dropdown} Solutions

```bash
# Check service status
systemctl --user status bazzite-ai-seeding

# View logs
journalctl --user -u bazzite-ai-seeding

# Restart service
systemctl --user restart bazzite-ai-seeding

# Regenerate config
just release-setup-seeding
```

::::

### GitHub Release Failures

**Problem:** "gh: command not found"

::::{dropdown} Solutions

```bash
# Install GitHub CLI
sudo dnf install gh

# Authenticate
gh auth login
```

::::

**Problem:** "Release already exists"

::::{dropdown} Solutions

```bash
# Delete existing release
gh release delete [tag]

# Then recreate
just release-create [tag]
```

::::

## Advanced Usage

### Custom Tags

```bash
# Release with custom tag
just release 42.custom-tag
```

### Skip Steps

```bash
# Just create torrents (if ISOs already built)
just release-create-torrents [tag]

# Just create GitHub release
just release-create [tag]
```

### Manual Torrent Management

```bash
# List torrents in directory
just release-torrents-info [tag]

# Upload to existing release
just release-upload [tag] file1 file2
```

## Release Utilities

### List All Releases

```bash
just release-list
```

Shows all releases in `releases/` directory.

### Clean Release Artifacts

```bash
# Prompts for confirmation
just release-clean
```

Removes ISOs, torrents, and releases directory.

### Verify Checksums

```bash
just release-verify
```

Verifies SHA256SUMS against ISOs.

## Why BitTorrent Distribution?

```{admonition} Design Decision
:class: tip

ISOs are 8+ GB each, exceeding GitHub's 2GB release asset limit. BitTorrent provides:

- **Scalability:** Distributed bandwidth from seeders
- **Reliability:** Resume interrupted downloads
- **Verification:** Built-in integrity checking
- **Cost:** No hosting fees or bandwidth limits
```

**Users can download via:**
1. `.torrent` files from GitHub releases
2. Magnet links (in release notes)
3. Any BitTorrent client (Transmission, qBittorrent, Deluge)

## Related Documentation

```{seealso}
- {doc}`iso-build` - ISO building details
- {doc}`../testing/index` - Testing guides
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [BitTorrent Protocol](https://www.bittorrent.org/beps/bep_0003.html)
```
