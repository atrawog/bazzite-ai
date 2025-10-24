# Simplified Containerfile for Bazzite AI
# Optimized for buildah registry cache compatibility with split package layers
#
# Architecture:
# - Direct file copies instead of bind mounts
# - 11 separate RUN layers for granular caching (3-layer package split)
# - No external cache mounts (DNF5, etc.)
# - Each layer only rebuilds if its source changes
# - Package installations split by change frequency for optimal caching
#
# Expected performance:
# - First build: ~6-8 minutes (downloads all packages)
# - Config-only changes: ~30-60 seconds (uses cached 600MB packages)
# - External package changes: ~1-2 minutes (uses cached 500MB base packages)
# - Base package changes: ~3-4 minutes (uses cached 100MB external packages)
# - Unchanged builds: <1 minute (if cache works)

ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG IMAGE_NAME="${IMAGE_NAME:-bazzite-ai}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-atrawog}"

# Copy all build files and system files upfront
# This replaces the previous scratch stage + bind mount strategy
COPY build_files /tmp/build_files
COPY system_files /tmp/system_files

# Layer 1: Copy system files to root filesystem
# Caches as long as system_files/ doesn't change
RUN mkdir -p /var/roothome && \
    cp -avf /tmp/system_files/. /

# Layer 2: Set image metadata and info
# Caches independently of other layers (small, medium frequency)
RUN IMAGE_NAME="${IMAGE_NAME}" \
    IMAGE_VENDOR="${IMAGE_VENDOR}" \
    /tmp/build_files/os/00-image-info.sh

# Layer 3: Install base packages (STABLE LAYER)
# - Largest layer (~500MB of core Fedora packages)
# - Changes rarely (only when adding/removing base packages)
# - Best cache hit rate (~80%)
RUN /tmp/build_files/os/10-base-packages.sh

# Layer 4: Install external packages (MODERATE LAYER)
# - Medium layer (~100MB external repos, COPR, VS Code, Docker, WinBoat, nvidia-container-toolkit)
# - Changes occasionally (when external dependencies updated)
# - Good cache hit rate (~60%)
RUN /tmp/build_files/os/20-external-packages.sh

# Layer 5: System configuration (VOLATILE LAYER)
# - Small layer (~10MB SDDM/GDM config, KDE settings, service enables)
# - Changes frequently (configuration tweaks)
# - Lower cache hit rate but fast rebuild (~30-60 seconds)
RUN /tmp/build_files/os/30-system-config.sh

# Layer 6: Configure systemd services
# Independent caching - only rebuilds if 40-services.sh changes
RUN /tmp/build_files/os/40-services.sh

# Layer 7: Fix /opt directory permissions
# Independent caching - only rebuilds if 50-fix-opt.sh changes
RUN /tmp/build_files/os/50-fix-opt.sh

# Layer 8: Remove gaming-specific configurations
# Independent caching - only rebuilds if 60-clean-base.sh changes
RUN /tmp/build_files/os/60-clean-base.sh

# Layer 9: Rebuild initramfs
# Only rebuilds if 99-build-initramfs.sh changes
RUN /tmp/build_files/os/99-build-initramfs.sh

# Layer 10: Final cleanup
# Runs cleanup script
RUN /tmp/build_files/os/999-cleanup.sh

# Layer 11: Remove build artifacts
# Removes temporary build files from the image
RUN rm -rf /tmp/build_files /tmp/system_files

# Image metadata labels
LABEL "containers.bootc"="1" \
      "io.artifacthub.package.deprecated"="false" \
      "io.artifacthub.package.keywords"="bootc,ublue,universal-blue" \
      "io.artifacthub.package.license"="Apache-2.0" \
      "io.artifacthub.package.logo-url"="https://avatars.githubusercontent.com/u/187439889?s=200&v=4" \
      "io.artifacthub.package.prerelease"="false" \
      "io.artifacthub.package.readme-url"="https://raw.githubusercontent.com/atrawog/bazzite-ai/refs/heads/main/README.md" \
      "org.opencontainers.image.created"="${BUILD_DATE}" \
      "org.opencontainers.image.description"="The Bazzite Developer Experience" \
      "org.opencontainers.image.documentation"="https://raw.githubusercontent.com/atrawog/bazzite-ai/refs/heads/main/README.md" \
      "org.opencontainers.image.licenses"="Apache-2.0" \
      "org.opencontainers.image.revision"="${GIT_COMMIT}" \
      "org.opencontainers.image.source"="https://github.com/atrawog/bazzite-ai/blob/main/Containerfile" \
      "org.opencontainers.image.title"="${IMAGE_NAME}" \
      "org.opencontainers.image.url"="https://github.com/atrawog/bazzite-ai" \
      "org.opencontainers.image.vendor"="${IMAGE_VENDOR}" \
      "org.opencontainers.image.version"="${VERSION}"
