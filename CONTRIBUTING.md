# Contributing to Bazzite AI

This repository is a fork of [ublue-os/bazzite-dx](https://github.com/ublue-os/bazzite-dx) with custom AI/ML-focused branding and tooling.

## Repository Structure

This fork maintains two branches:

- **`main`**: The development branch with Bazzite AI branding and customizations
- **`upstream-main`**: A clean tracking branch of upstream `ublue-os/bazzite-dx:main`

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

When merging upstream changes, you will typically encounter conflicts in these branding-specific files:

- `README.md` - Keep bazzite-ai branding
- `Justfile` - Keep atrawog/bazzite-ai defaults
- `Containerfile` - Keep bazzite-ai image name and atrawog vendor
- `iso.toml` - Keep ghcr.io/atrawog/bazzite-ai URL
- `.github/workflows/build.yml` - Keep bazzite-ai image name transform
- `.github/CODEOWNERS` - Keep @atrawog
- `artifacthub-repo.yml` - Keep atrawog owner info
- `CLAUDE.md` - Keep bazzite-ai references
- `build_files/60-clean-base.sh` - Keep 95-bazzite-ai.just reference
- `system_files/usr/share/ublue-os/just/95-bazzite-ai.just` - May need manual reconciliation

**Resolution Strategy**: Always favor the fork-specific branding in these files.

## Contributing Back to Upstream

To contribute improvements back to `ublue-os/bazzite-dx`:

### 1. Create a Feature Branch from `upstream-main`

```bash
# Switch to upstream-main branch
git checkout upstream-main

# Pull latest upstream changes
git pull upstream main

# Create a feature branch
git checkout -b feature/my-contribution
```

### 2. Cherry-Pick or Develop Changes

If the change exists in `main`:

```bash
# Cherry-pick specific commits (exclude branding changes)
git cherry-pick <commit-hash>
```

Or develop the feature directly on the feature branch.

### 3. Ensure No Branding in Contribution

Before submitting, verify that none of these files contain fork-specific branding:

```bash
# Check for bazzite-ai references
git diff upstream/main | grep -i "bazzite-ai"

# Check for atrawog references
git diff upstream/main | grep -i "atrawog"
```

If found, those changes should NOT be in your upstream contribution.

### 4. Push and Create Pull Request

```bash
# Push feature branch to your fork
git push origin feature/my-contribution
```

Then create a Pull Request from `atrawog/bazzite-ai:feature/my-contribution` to `ublue-os/bazzite-dx:main` on GitHub.

## Files Compatible with Upstream

These files can be contributed back without modification:

- `build_files/00-image-info.sh` (uses build args)
- `build_files/20-install-apps.sh` (package installations)
- `build_files/40-services.sh` (service configuration)
- `build_files/50-fix-opt.sh` (opt directory fixes)
- `build_files/60-clean-base.sh` (if renamed back to bazzite-dx.just)
- `build_files/99-build-initramfs.sh` (initramfs rebuild)
- `build_files/999-cleanup.sh` (cleanup scripts)
- `image.toml` (VM configuration)
- `.github/renovate.json5` (dependency automation)
- `image-versions.yaml` (base image tracking)

## Fork-Specific Files

These files should NEVER be contributed to upstream:

- `README.md` - Contains fork description and atrawog/bazzite-ai URLs
- `Justfile` - Contains atrawog/bazzite-ai defaults
- `Containerfile` - Contains bazzite-ai image name
- `iso.toml` - Contains ghcr.io/atrawog/bazzite-ai URL
- `.github/workflows/build.yml` - Contains bazzite-ai transform
- `.github/CODEOWNERS` - Contains @atrawog
- `artifacthub-repo.yml` - Contains atrawog owner
- `CLAUDE.md` - Fork-specific documentation
- `CONTRIBUTING.md` - This file
- `system_files/usr/share/ublue-os/just/95-bazzite-ai.just` - Fork-specific commands

## Questions?

For fork-specific issues, open an issue at [atrawog/bazzite-ai](https://github.com/atrawog/bazzite-ai/issues).

For upstream contributions, follow the [ublue-os/bazzite-dx contributing guidelines](https://github.com/ublue-os/bazzite-dx).
