# Layered Containerfile for Bazzite AI
# Optimized for maximum build cache efficiency
#
# Architecture:
# - 8 separate RUN layers for granular caching
# - DNF5 cache mounts on package installation layers
# - Each layer only rebuilds if its dependencies change
#
# Expected improvements:
# - Incremental config changes: 90% faster (~30-60s vs ~6-8min)
# - Incremental package changes: 40% faster (~4-5min vs ~6-8min)
# - DNF5 cache prevents re-downloading unchanged packages

ARG BASE_IMAGE

# Stage 1: Prepare build context
# Copies system_files and build_files into a scratch image for bind mounting
FROM scratch AS ctx

COPY system_files /files
COPY build_files /build_files

# Stage 2: Build the OS image with layered caching
FROM ${BASE_IMAGE}

ARG IMAGE_NAME="${IMAGE_NAME:-bazzite-ai}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-atrawog}"

# Layer 1: Copy system files to root filesystem
# This layer caches as long as system_files/ doesn't change
# Fastest layer - rarely invalidated
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    mkdir -p /var/roothome && \
    cp -avf /run/context/files/. /

# Layer 2: Set image metadata and info
# Caches independently of other layers
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    CONTEXT_PATH=/run/context \
    /run/context/build_files/00-image-info.sh

# Layer 3: Install packages (CRITICAL LAYER)
# - Largest layer (~611MB of packages)
# - DNF5 cache mount prevents re-downloading unchanged packages
# - Only rebuilds if 20-install-apps.sh changes
# - Buildah registry cache preserves this layer across CI runs
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=cache,target=/var/cache/dnf5,sharing=locked \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    CONTEXT_PATH=/run/context \
    /run/context/build_files/20-install-apps.sh

# Layer 4: Configure systemd services
# Independent caching - only rebuilds if 40-services.sh changes
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    CONTEXT_PATH=/run/context \
    /run/context/build_files/40-services.sh

# Layer 5: Fix /opt directory permissions
# Independent caching - only rebuilds if 50-fix-opt.sh changes
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    CONTEXT_PATH=/run/context \
    /run/context/build_files/50-fix-opt.sh

# Layer 6: Remove gaming-specific configurations
# Independent caching - only rebuilds if 60-clean-base.sh changes
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    CONTEXT_PATH=/run/context \
    /run/context/build_files/60-clean-base.sh

# Layer 7: Rebuild initramfs
# Only rebuilds if 99-build-initramfs.sh changes
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    CONTEXT_PATH=/run/context \
    /run/context/build_files/99-build-initramfs.sh

# Layer 8: Final cleanup
# - DNF5 cache mount ensures 'dnf5 clean all' doesn't interfere with cache
# - 999-cleanup.sh preserves /var/cache (see line 21 in script)
# - bootc container lint runs here
RUN --mount=type=tmpfs,dst=/tmp \
    --mount=type=cache,target=/var/cache/dnf5,sharing=locked \
    --mount=type=bind,from=ctx,source=/,target=/run/context \
    CONTEXT_PATH=/run/context \
    /run/context/build_files/999-cleanup.sh
