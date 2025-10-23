# Bazzite AI Release Process

This document provides a comprehensive guide for creating a new Bazzite AI release with fresh ISO builds, BitTorrent distribution, and GitHub release creation.

## Overview

A complete release involves:
1. Building fresh ISO installers from the latest container images
2. Creating torrent files for BitTorrent distribution
3. Setting up seeding to distribute ISOs to users
4. Publishing the release on GitHub with download instructions

**Time Estimate:** 90-150 minutes (mostly ISO build time)
**Disk Space Required:** ~20GB for ISOs
**Prerequisites:** GitHub CLI authentication, transmission tools

---

## Pre-Release Checklist

Before starting a release, ensure:

- [ ] Latest CI build succeeded on GitHub Actions
- [ ] Container images are published to GHCR
  ```bash
  # Check images exist
  podman pull ghcr.io/atrawog/bazzite-ai:latest
  podman pull ghcr.io/atrawog/bazzite-ai:latest
  ```
- [ ] All prerequisites are met
  ```bash
  just release-check-prereqs
  ```
- [ ] Sufficient disk space available (~20GB)
- [ ] GitHub CLI authenticated
  ```bash
  gh auth status
  ```
- [ ] You have 2+ hours available (for ISO builds)

---

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

---

## Detailed Step-by-Step Process

### Step 0: Verify Prerequisites

```bash
just release-check-prereqs
```

This checks:
- ✓ Container runtime (podman/docker)
- ✓ GitHub CLI installed and authenticated
- ✓ Torrent creation tools (transmission-create)
- ✓ Torrent management tools (transmission-daemon, transmission-show)
- ✓ Sufficient disk space (~20GB)
- ✓ Seeding service setup (optional)

**If any checks fail:**
- Follow the instructions provided by the check
- Install missing tools with: `just release-install-tools`
- Authenticate GitHub CLI: `gh auth login`

### Step 1: Pull Latest Container Images

```bash
just release-pull [tag]
```

This pulls the latest container images from GHCR:
- `ghcr.io/atrawog/bazzite-ai:latest`
- `ghcr.io/atrawog/bazzite-ai:latest`

**What it does:**
- Pulls images from GitHub Container Registry
- Tags them locally as `localhost/bazzite-ai:latest`
- Prepares images for ISO building

**Time:** ~5-10 minutes (depending on network speed)

### Step 2: Build Fresh ISOs

```bash
just release-build-isos [tag]
```

This builds the unified ISO using bootc-image-builder:
- `bazzite-ai-{tag}.iso` - Base ISO for AMD/Intel GPUs (~8.2GB)
- `bazzite-ai-{tag}.iso` - NVIDIA ISO (~8.3GB)

**What it does:**
- Checks if ISOs already exist (prompts to rebuild if found)
- Builds base ISO from `localhost/bazzite-ai:latest` (30-60 min)
- Builds NVIDIA ISO from `localhost/bazzite-ai:latest` (30-60 min)
- Moves built ISOs from `output/bootiso/` to root directory

**Time:** 60-120 minutes total (30-60 minutes per ISO)

**Note:** This is the longest step. ISOs are built fresh from the latest container images to ensure users get the most up-to-date system.

### Step 3: Generate Checksums

```bash
just release-checksums
```

This creates SHA256 checksums for verification:

**What it does:**
- Generates `SHA256SUMS` file with checksums for the ISO
- Verifies checksums immediately
- Displays checksums for review

**Output:**
```
SHA256SUMS:
<hash>  bazzite-ai-42.20251023.iso
<hash>  bazzite-ai-42.20251023.iso
```

**Time:** < 1 minute

### Step 4: Organize Release Files

```bash
just release-organize [tag]
```

This organizes files into the release directory structure:

**What it does:**
- Creates `releases/{tag}/` directory
- Moves ISOs, torrents, and checksums into it
- Updates `releases/latest` symlink to point to new release

**Directory structure:**
```
releases/
├── 42.20251023/
│   ├── bazzite-ai-42.20251023.iso
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

This creates .torrent files for BitTorrent distribution:

**What it does:**
- Creates `.torrent` files for the ISO
- Uses 6 public trackers for open source distribution
- Generates magnet links in `{tag}-magnets.txt`
- Saves everything to `releases/{tag}/`

**Torrent Configuration:**
- **Trackers:** 6 public trackers (opentrackr, stealth.si, etc.)
- **Piece Size:** Automatic (optimal for 8GB files)
- **Comment:** Includes project description

**Time:** ~2 minutes

### Step 6: Verify Torrents

```bash
just release-verify-torrents [tag]
```

This verifies torrent files are valid:

**What it does:**
- Checks torrent files exist and are valid
- Verifies ISOs exist and match torrent metadata
- Ensures magnet links were generated correctly

**Time:** < 1 minute

### Step 7: Start Seeding

```bash
# First time only: Set up seeding service
just release-setup-seeding

# Add torrents to seeder
just release-seed-start [tag]
```

This starts seeding the ISOs to help users download:

**What it does:**
- Sets up transmission-daemon as systemd user service (first time only)
- Starts the seeding service
- Adds both torrent files to the seeder
- Begins uploading to peers

**Seeding Configuration:**
- **Service:** systemd user service `bazzite-ai-seeding.service`
- **Daemon:** transmission-daemon
- **Ratio Limit:** 2.0 (seeds to 200% uploaded, then stops)
- **Port:** 51413 (peer connections)
- **RPC Port:** 9091 (localhost only, for control)

**Time:** ~2 minutes

**Monitor seeding:**
```bash
just release-seed-status
```

### Step 8: Create GitHub Release

```bash
just release-create [tag]
```

This creates the GitHub release with download instructions:

**What it does:**
- Checks if release already exists (prompts to recreate)
- Uploads `.torrent` files (small, ~50KB each)
- Uploads `SHA256SUMS` file
- Generates release notes with:
  - File sizes (dynamically calculated)
  - Magnet links for the ISO
  - BitTorrent download instructions
  - Rebase instructions for existing users
  - Verification instructions

**Release Assets:**
- `bazzite-ai-{tag}.iso.torrent` (~50KB)
- `bazzite-ai-{tag}.iso.torrent` (~50KB)
- `SHA256SUMS` (text file)

**Note:** ISO files themselves are NOT uploaded to GitHub (they exceed the 2GB limit). Users download them via BitTorrent.

**Time:** ~1 minute

---

## One-Command Release

Run the entire workflow with a single command:

```bash
just release [tag]
```

This automatically runs all 8 steps in sequence.

**What happens:**
1. ✓ Checks prerequisites (exits if any fail)
2. Prompts for confirmation
3. Runs all 8 steps with progress indicators
4. Reports completion status
5. Provides next steps for seeding management

---

## Post-Release Verification

After the release completes, verify everything worked:

### 1. Check Release Status

```bash
just release-status [tag]
```

Verify:
- ✓ Container images pulled
- ✓ ISOs exist with correct sizes
- ✓ Checksums generated
- ✓ Torrents created
- ✓ Seeding active
- ✓ GitHub release created

### 2. Verify Seeding

```bash
just release-seed-status
```

Should show:
- ✓ Service running
- ✓ 2 active torrents
- Upload/download statistics

### 3. Test GitHub Release

```bash
gh release view [tag]
```

Or visit: `https://github.com/atrawog/bazzite-ai/releases/tag/{tag}`

Verify:
- ✓ Release notes include file sizes
- ✓ Magnet links are present and properly formatted
- ✓ .torrent files are downloadable
- ✓ SHA256SUMS is available

### 4. Test Torrent Download

Download one of the .torrent files and open it in a BitTorrent client to verify:
- ✓ Torrent loads correctly
- ✓ ISO file is recognized
- ✓ Download starts (even if slowly at first)

---

## Seeding Management

### Start Seeding

```bash
just release-seed-start [tag]
```

### Check Seeding Status

```bash
just release-seed-status
```

Shows:
- Service status (running/stopped)
- Active torrents count
- Upload/download rates
- Ratio for each torrent

### Stop Seeding

```bash
just release-seed-stop
```

**Note:** Seeding stops automatically when torrents reach 2.0 ratio (200% uploaded).

### View Seeding Logs

```bash
journalctl --user -u bazzite-ai-seeding -f
```

---

## Troubleshooting

### ISO Build Failures

**Problem:** ISO build fails with "No space left on device"

**Solution:**
```bash
# Check available space
df -h .

# Clean old artifacts
just release-clean
just sudo-clean

# Remove old releases if needed
rm -rf releases/old-tag/
```

**Problem:** ISO build fails with container errors

**Solution:**
```bash
# Ensure images are pulled fresh
just release-pull [tag]

# Check if images exist
podman images | grep bazzite-ai

# Try building ISOs one at a time
just build-iso localhost/bazzite-ai latest
just build-iso-nvidia localhost/bazzite-ai latest
```

### Torrent Creation Failures

**Problem:** `mktorrent: command not found`

**Solution:**
```bash
# transmission-create is used as fallback automatically
# Verify it's installed
command -v transmission-create

# If not installed
sudo rpm-ostree install transmission-cli
sudo rpm-ostree apply-live
```

**Problem:** Magnet links not generated

**Solution:**
```bash
# Check if transmission-show is installed
command -v transmission-show

# If not, install it
sudo rpm-ostree install transmission-cli
sudo rpm-ostree apply-live

# Recreate torrents
just release-create-torrents [tag]
```

### Seeding Issues

**Problem:** "Seeding service not set up"

**Solution:**
```bash
# Run the setup script
just release-setup-seeding

# This creates:
# - systemd user service
# - transmission-daemon config
# - Enable the service
```

**Problem:** "Cannot connect to transmission-daemon"

**Solution:**
```bash
# Check service status
systemctl --user status bazzite-ai-seeding

# View logs
journalctl --user -u bazzite-ai-seeding -n 50

# Restart service
systemctl --user restart bazzite-ai-seeding

# If still failing, check config
cat .transmission-daemon.json
```

**Problem:** Seeding uses too much bandwidth

**Solution:**
```bash
# Edit .transmission-daemon.json
# Set upload limit:
"speed-limit-up": 1000,  # 1000 KB/s = 1 MB/s
"speed-limit-up-enabled": true,

# Restart service
systemctl --user restart bazzite-ai-seeding
```

### GitHub Release Failures

**Problem:** "gh not authenticated"

**Solution:**
```bash
# Authenticate with GitHub
gh auth login

# Follow the prompts to authenticate
# Choose: GitHub.com, HTTPS, Login with browser
```

**Problem:** "Release already exists"

**Solution:**
```bash
# The script will prompt to delete and recreate
# Or delete manually:
gh release delete [tag] --yes
just release-create [tag]
```

**Problem:** File sizes show as "unknown" in release notes

**Solution:**
```bash
# Ensure ISOs are in releases/{tag}/ directory
just release-organize [tag]

# Verify ISOs exist
ls -lh releases/{tag}/*.iso

# Recreate release
just release-create [tag]
```

---

## Best Practices

### Timing

- **Best time:** Start in the morning (ISOs take 1-2 hours)
- **Avoid:** Don't start late in the day if you need to monitor it
- **Background:** ISO builds can run in background, but monitor for errors

### Disk Space

- **Before release:** Clean old artifacts
  ```bash
  just release-clean
  just sudo-clean
  ```
- **After release:** Keep at least the latest 2 releases
- **Monitor:** Check disk space regularly
  ```bash
  df -h .
  ```

### Seeding

- **Start immediately:** Begin seeding as soon as torrents are created
- **Seed for at least 48 hours:** Give early adopters time to download
- **Monitor ratio:** Ensure you reach at least 2.0 ratio (200% uploaded)
- **Multiple seeders:** If possible, seed from multiple locations

### Communication

- **Announce on GitHub:** Create a release announcement
- **Social media:** Share release on relevant channels
- **Discord/Forums:** Notify community members
- **Include magnet links:** In all announcements for easy access

### Testing

- **Test torrents:** Download one yourself to verify it works
- **Test installation:** Boot one ISO in a VM to ensure it works
- **Check links:** Verify all download links in release notes work

---

## FAQ

**Q: Why BitTorrent instead of direct downloads?**
A: ISO files are 8+ GB each, exceeding GitHub's 2GB file size limit. BitTorrent provides distributed bandwidth and is ideal for large file distribution.

**Q: How long should I seed?**
A: Seed until reaching 2.0 ratio (200% uploaded) or at least 48 hours. The service automatically stops at 2.0 ratio.

**Q: Can I build ISOs without seeding?**
A: Yes, seeding is optional. You can still create torrents and upload them to GitHub. Other users or mirrors can seed.

**Q: What if ISO build fails?**
A: Check disk space, verify container images are pulled, and review logs. You can build ISOs individually with `just build-iso` and `just build-iso-nvidia`.

**Q: Can I skip the prerequisite check?**
A: Not recommended. The check prevents wasting time on builds that will fail. If needed, run steps individually instead of using `just release`.

**Q: How do I update an existing release?**
A: Delete the existing release with `gh release delete [tag]`, then run `just release-create [tag]` again. Or use `just release-upload [tag] [files]` to add files.

**Q: Can I release from a different tag?**
A: Yes, specify the tag: `just release 42.YYYYMMDD`. The default is today's date: `42.$(date +%Y%m%d)`.

**Q: How do I clean up old releases?**
A: Delete the release on GitHub with `gh release delete [tag]`, then remove the local directory: `rm -rf releases/[tag]/`.

---

## Quick Reference

### Commands

| Command | Purpose | Time |
|---------|---------|------|
| `just release-check-prereqs` | Verify prerequisites | <1 min |
| `just release-status [tag]` | Show current status | <1 min |
| `just release` | Full release workflow | 90-150 min |
| `just release-pull [tag]` | Pull container images | 5-10 min |
| `just release-build-isos [tag]` | Build the ISO | 30-60 min |
| `just release-checksums` | Generate checksums | <1 min |
| `just release-organize [tag]` | Organize files | <1 min |
| `just release-create-torrents [tag]` | Create torrents | 2 min |
| `just release-verify-torrents [tag]` | Verify torrents | <1 min |
| `just release-seed-start [tag]` | Start seeding | 2 min |
| `just release-seed-status` | Check seeding | <1 min |
| `just release-create [tag]` | Create GitHub release | 1 min |

### Files

| File | Purpose |
|------|---------|
| `releases/{tag}/*.iso` | ISO installer files (~8GB each) |
| `releases/{tag}/*.torrent` | Torrent files for distribution (~50KB each) |
| `releases/{tag}/SHA256SUMS` | Checksums for verification |
| `releases/{tag}/{tag}-magnets.txt` | Magnet links |
| `.transmission-daemon.json` | Seeding daemon configuration |

### Disk Space

- **ISO files:** ~17GB total (8.2GB + 8.3GB)
- **Torrent files:** ~100KB total
- **Checksum file:** <1KB
- **Total per release:** ~17GB

---

## Support

If you encounter issues not covered in this document:

1. Check the [GitHub Issues](https://github.com/atrawog/bazzite-ai/issues)
2. Review the [main documentation](../README.md)
3. Check [CLAUDE.md](../CLAUDE.md) for technical details
4. Ask in the community forums or Discord
