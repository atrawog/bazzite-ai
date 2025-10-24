# Simplified Containerfile for Bazzite AI
# Optimized for buildah registry cache compatibility
#
# Architecture:
# - Direct file copies instead of bind mounts
# - 9 separate RUN layers for granular caching
# - No external cache mounts (DNF5, etc.)
# - Each layer only rebuilds if its source changes
#
# Expected performance:
# - First build: ~6-8 minutes (downloads all packages)
# - Incremental config changes: ~30-60 seconds (if cache works)
# - Incremental package changes: ~4-5 minutes (if cache works)
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
# Caches independently of other layers
RUN IMAGE_NAME="${IMAGE_NAME}" \
    IMAGE_VENDOR="${IMAGE_VENDOR}" \
    /tmp/build_files/00-image-info.sh

# Layer 3: Install packages (CRITICAL LAYER)
# - Largest layer (~611MB of packages)
# - Only rebuilds if 20-install-apps.sh changes
# - Cleanup happens within the script
RUN /tmp/build_files/20-install-apps.sh

# Layer 4: Configure systemd services
# Independent caching - only rebuilds if 40-services.sh changes
RUN /tmp/build_files/40-services.sh

# Layer 5: Fix /opt directory permissions
# Independent caching - only rebuilds if 50-fix-opt.sh changes
RUN /tmp/build_files/50-fix-opt.sh

# Layer 6: Remove gaming-specific configurations
# Independent caching - only rebuilds if 60-clean-base.sh changes
RUN /tmp/build_files/60-clean-base.sh

# Layer 7: Rebuild initramfs
# Only rebuilds if 99-build-initramfs.sh changes
RUN /tmp/build_files/99-build-initramfs.sh

# Layer 8: Final cleanup
# Runs cleanup script
RUN /tmp/build_files/999-cleanup.sh

# Layer 9: Remove build artifacts
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
