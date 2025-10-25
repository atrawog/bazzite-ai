# Optimized Containerfile for Bazzite AI
# Granular script copying for maximum cache efficiency
#
# Architecture:
# - Each script copied individually RIGHT BEFORE execution
# - Changing script N only invalidates layers N onwards
# - Expensive operations (initramfs) placed BEFORE volatile content (system_files)
# - System files copied LATE to avoid invalidating package cache
#
# Expected performance:
# - First build: ~6-8 minutes (downloads all packages)
# - Ujust/config changes: ~15-30s (uses cached packages + initramfs) ⚡
# - External package changes: ~2-3min (uses cached base packages)
# - Base package changes: ~4-5min (uses cached external packages)
# - Unchanged builds: <1 minute (full cache hit)
#
# Layer invalidation examples:
# - Edit 100-copy-system-files.sh → Only layers 10-12 rebuild (~15-30s)
# - Edit 30-system-config.sh → Layers 5-12 rebuild (~1-2min)
# - Edit 20-external-packages.sh → Layers 4-12 rebuild (~2-3min)
# - Edit 10-base-packages.sh → Layers 3-12 rebuild (~4-5min)

ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG IMAGE_NAME="${IMAGE_NAME:-bazzite-ai}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-atrawog}"

# Layer 1: Create root home directory
# Early setup needed before configuration scripts
RUN mkdir -p /var/roothome

# Layer 2-3: Set image metadata and info
# Caches independently of other layers (small, medium frequency)
COPY build_files/os/00-image-info.sh /tmp/build_files/os/
RUN IMAGE_NAME="${IMAGE_NAME}" \
    IMAGE_VENDOR="${IMAGE_VENDOR}" \
    /tmp/build_files/os/00-image-info.sh

# Layer 4-5: Install base packages (STABLE LAYER)
# - Largest layer (~500MB of core Fedora packages)
# - Changes rarely (only when adding/removing base packages)
# - Best cache hit rate (~80%)
COPY build_files/os/10-base-packages.sh /tmp/build_files/os/
RUN /tmp/build_files/os/10-base-packages.sh

# Layer 6-7: Install external packages (MODERATE LAYER)
# - Medium layer (~100MB external repos, COPR, VS Code, Docker, WinBoat, nvidia-container-toolkit)
# - Changes occasionally (when external dependencies updated)
# - Good cache hit rate (~60%)
COPY build_files/os/20-external-packages.sh /tmp/build_files/os/
RUN /tmp/build_files/os/20-external-packages.sh

# Layer 8-9: System configuration (VOLATILE LAYER)
# - Small layer (~10MB SDDM/GDM config, KDE settings, service enables)
# - Changes frequently (configuration tweaks)
# - Lower cache hit rate but fast rebuild (~30-60 seconds)
COPY build_files/os/30-system-config.sh /tmp/build_files/os/
RUN /tmp/build_files/os/30-system-config.sh

# Layer 10-11: Configure systemd services
# Independent caching - only rebuilds if 40-services.sh changes
COPY build_files/os/40-services.sh /tmp/build_files/os/
RUN /tmp/build_files/os/40-services.sh

# Layer 12-13: Fix /opt directory permissions
# Independent caching - only rebuilds if 50-fix-opt.sh changes
COPY build_files/os/50-fix-opt.sh /tmp/build_files/os/
RUN /tmp/build_files/os/50-fix-opt.sh

# Layer 14-15: Remove gaming-specific configurations
# Independent caching - only rebuilds if 60-clean-base.sh changes
COPY build_files/os/60-clean-base.sh /tmp/build_files/os/
RUN /tmp/build_files/os/60-clean-base.sh

# Layer 16-17: Rebuild initramfs (EXPENSIVE but STABLE)
# - Takes ~30-60 seconds to build
# - Only rebuilds when kernel or this script changes
# - Placed BEFORE system_files to avoid unnecessary rebuilds on ujust changes
COPY build_files/os/99-build-initramfs.sh /tmp/build_files/os/
RUN /tmp/build_files/os/99-build-initramfs.sh

# Layer 18-19: Copy system files to root filesystem (LATE - VOLATILE LAYER)
# - Contains ujust recipes, configs, flatpak lists, VS Code settings
# - Moved AFTER all package installations and initramfs to prevent cache invalidation
# - Changes to ujust files now only rebuild from this point forward
# - Avoids reinstalling 600MB of packages when just files change
COPY system_files /tmp/system_files
COPY build_files/os/100-copy-system-files.sh /tmp/build_files/os/
RUN /tmp/build_files/os/100-copy-system-files.sh

# Layer 20-21: Final cleanup
# Runs cleanup script (container lint, final dnf cleanup)
COPY build_files/os/999-cleanup.sh /tmp/build_files/os/
RUN /tmp/build_files/os/999-cleanup.sh

# Layer 22: Remove build artifacts
# Removes temporary build files and system_files from the image
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
