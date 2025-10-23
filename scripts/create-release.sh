#!/usr/bin/env bash
# Bazzite AI ISO Release Script
# This script automates building ISOs and creating GitHub releases

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO="atrawog/bazzite-ai"
IMAGE_BASE="ghcr.io/atrawog/bazzite-ai"
IMAGE_NVIDIA="ghcr.io/atrawog/bazzite-ai"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_tools=()

    command -v just >/dev/null 2>&1 || missing_tools+=("just")
    command -v podman >/dev/null 2>&1 || missing_tools+=("podman")
    command -v gh >/dev/null 2>&1 || missing_tools+=("gh")
    command -v sha256sum >/dev/null 2>&1 || missing_tools+=("coreutils")

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install with: sudo dnf install ${missing_tools[*]}"
        exit 1
    fi

    # Check KVM support
    if [ ! -e /dev/kvm ]; then
        log_error "/dev/kvm not found. KVM support is required for ISO building."
        exit 1
    fi

    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo access for building ISOs."
        sudo -v || { log_error "Failed to obtain sudo access"; exit 1; }
    fi

    log_success "All prerequisites met"
}

# Determine release tag
determine_tag() {
    log_info "Determining release tag..."

    # Try to get tag from container image
    TAG=$(skopeo inspect docker://${IMAGE_BASE}:latest | jq -r '.Labels."org.opencontainers.image.version"' || echo "")

    if [ -z "$TAG" ] || [ "$TAG" == "null" ]; then
        # Fall back to date-based tag
        TAG="42.$(date +%Y%m%d)"
        log_warn "Could not determine tag from container image, using: $TAG"
    else
        log_info "Using tag from container image: $TAG"
    fi

    # Check if release already exists
    if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
        log_warn "Release $TAG already exists!"
        if ! confirm "Do you want to delete and recreate it?"; then
            log_error "Aborted"
            exit 1
        fi
        log_info "Deleting existing release..."
        gh release delete "$TAG" -R "$REPO" --yes
    fi

    echo "$TAG"
}

# Pull and tag container images
pull_images() {
    local tag=$1
    log_info "Pulling container images..."

    log_info "Pulling ${IMAGE_BASE}:${tag}..."
    podman pull "${IMAGE_BASE}:${tag}" || podman pull "${IMAGE_BASE}:latest"

    log_info "Pulling ${IMAGE_NVIDIA}:${tag}..."
    podman pull "${IMAGE_NVIDIA}:${tag}" || podman pull "${IMAGE_NVIDIA}:latest"

    log_info "Tagging images for local use..."
    podman tag "${IMAGE_BASE}:latest" localhost/bazzite-ai:latest
    podman tag "${IMAGE_NVIDIA}:latest" localhost/bazzite-ai:latest

    log_success "Images ready"
}

# Build ISOs
build_isos() {
    local tag=$1
    local iso_base="bazzite-ai-${tag}.iso"
    local iso_nvidia="bazzite-ai-${tag}.iso"

    log_info "Building base ISO (this will take 30-60 minutes)..."
    just build-iso localhost/bazzite-ai latest

    if [ -f "output/bootiso/install.iso" ]; then
        mv output/bootiso/install.iso "$iso_base"
        log_success "Base ISO created: $iso_base"
    else
        log_error "Base ISO build failed"
        exit 1
    fi

    log_info "Building NVIDIA ISO (this will take 30-60 minutes)..."
    just build-iso-nvidia localhost/bazzite-ai latest

    if [ -f "output/bootiso/install.iso" ]; then
        mv output/bootiso/install.iso "$iso_nvidia"
        log_success "NVIDIA ISO created: $iso_nvidia"
    else
        log_error "NVIDIA ISO build failed"
        exit 1
    fi

    echo "$iso_base,$iso_nvidia"
}

# Generate checksums
generate_checksums() {
    local iso_base=$1
    local iso_nvidia=$2

    log_info "Generating SHA256 checksums..."
    sha256sum "$iso_base" "$iso_nvidia" > SHA256SUMS

    log_info "Verifying checksums..."
    sha256sum -c SHA256SUMS

    log_success "Checksums generated and verified"
}

# Create GitHub release
create_release() {
    local tag=$1
    local iso_base=$2
    local iso_nvidia=$3

    log_info "Creating GitHub release $tag..."

    # Get base image digest for release notes
    local base_digest=$(podman inspect localhost/bazzite-ai:latest | jq -r '.[0].Digest' || echo "unknown")
    local nvidia_digest=$(podman inspect localhost/bazzite-ai:latest | jq -r '.[0].Digest' || echo "unknown")

    gh release create "$tag" \
      --repo "$REPO" \
      --title "Bazzite AI ${tag}" \
      --notes "# Bazzite AI ${tag}

## Container Images

- \`${IMAGE_BASE}:${tag}\` (Digest: ${base_digest})
- \`${IMAGE_NVIDIA}:${tag}\` (Digest: ${nvidia_digest})

All images are signed with cosign and can be verified using the public key in this repository.

## ISO Downloads

Download the appropriate ISO for your hardware:

- **${iso_base}** - For AMD/Intel GPUs (KDE Plasma)
- **${iso_nvidia}** - For NVIDIA GPUs (KDE Plasma)

**Important:** Always verify your download using the provided SHA256 checksums:
\`\`\`bash
sha256sum -c SHA256SUMS
\`\`\`

## Installation

### Fresh Install
1. Download the appropriate ISO
2. Create a bootable USB using [Fedora Media Writer](https://fedoraproject.org/workstation/download)
3. Boot from USB and follow installation prompts

### For Existing Bazzite Users

Rebase to this version:

**AMD/Intel GPUs:**
\`\`\`bash
rpm-ostree rebase ostree-image-signed:docker://${IMAGE_BASE}:${tag}
\`\`\`

**NVIDIA GPUs:**
\`\`\`bash
rpm-ostree rebase ostree-image-signed:docker://${IMAGE_NVIDIA}:${tag}
\`\`\`

Then reboot to complete the update.

## Documentation

- [Installation Guide](https://github.com/${REPO}#installation)
- [ISO Build Instructions](https://github.com/${REPO}/blob/main/docs/ISO-BUILD.md)

---

Built with Claude Code: https://claude.com/claude-code
" \
      "${iso_base}" \
      "${iso_nvidia}" \
      SHA256SUMS

    log_success "Release created: https://github.com/${REPO}/releases/tag/${tag}"
}

# Main execution
main() {
    echo
    log_info "Bazzite AI Release Builder"
    echo "================================"
    echo

    check_prerequisites

    TAG=$(determine_tag)

    log_info "Building release: $TAG"
    echo

    if ! confirm "Continue with building ISOs for release $TAG?"; then
        log_error "Aborted by user"
        exit 1
    fi

    # Step 1: Pull images
    pull_images "$TAG"

    # Step 2: Build ISOs
    IFS=',' read -r ISO_BASE ISO_NVIDIA <<< "$(build_isos "$TAG")"

    # Step 3: Generate checksums
    generate_checksums "$ISO_BASE" "$ISO_NVIDIA"

    # Step 4: Create release
    if confirm "ISOs built successfully. Create GitHub release?"; then
        create_release "$TAG" "$ISO_BASE" "$ISO_NVIDIA"
    else
        log_info "Skipping release creation"
        log_info "ISO files: $ISO_BASE, $ISO_NVIDIA"
        log_info "Checksums: SHA256SUMS"
        log_info "Create release manually with:"
        echo "  gh release create $TAG ${ISO_BASE} ${ISO_NVIDIA} SHA256SUMS -R $REPO"
    fi

    echo
    log_success "All done!"
    echo
}

# Run main function
main "$@"
