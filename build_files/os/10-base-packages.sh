#!/usr/bin/bash
set -xeuo pipefail

# Core development tools - stable package list, rarely changes
# This layer caches well (~500MB, rebuilt only when packages added/removed)

dnf5 install -y \
    alsa-lib-devel \
    android-tools \
    arch-install-scripts \
    autoconf \
    automake \
    bcc \
    bpftop \
    bpftrace \
    bridge-utils \
    ccache \
    ceph-fuse \
    cloud-init \
    cloud-utils-cloud-localds \
    cloud-utils-growpart \
    cloud-utils-mount-image-callback \
    cloud-utils-resize-part-image \
    cloud-utils-vcs-run \
    cloud-utils-write-mime-multipart \
    debootstrap \
    dislocker \
    dotnet-sdk-9.0 \
    ecryptfs-utils \
    fdupes \
    flatpak-builder \
    fuse-devel \
    fuse-dislocker \
    fuse3-devel \
    gh \
    git-lfs \
    golang-bazil-fuse-devel \
    golang-bin \
    html2text \
    htop \
    jack-audio-connection-kit-devel \
    jdupes \
    kaffeine \
    keepassxc \
    libtool \
    liquidctl \
    lm_sensors \
    nicstat \
    nodejs20 \
    nodejs20-devel \
    nodejs20-full-i18n \
    nodejs20-npm \
    nodejs-npm \
    numactl \
    pavucontrol \
    pcp \
    pcp-system-tools \
    php \
    podman-compose \
    podman-machine \
    podman-remote \
    podman-tui \
    powertop \
    python3-devel \
    python3-keepassxc-browser \
    python3-ramalama \
    python3-tkinter \
    qemu-kvm \
    qemu-user-binfmt \
    qemu-user-static \
    qjackctl \
    restic \
    rclone \
    rpm-sign \
    sirikali \
    squashfuse \
    strace \
    syncthing \
    syncthing-tools \
    sysprof \
    sysstat \
    Thunar \
    tiptop \
    transmission \
    transmission-cli \
    transmission-daemon \
    transmission-qt \
    mktorrent \
    usbmuxd \
    vlc \
    wireshark \
    xorg-x11-server-devel \
    xorg-x11-server-Xorg \
    zsh \
    apptainer \
    apptainer-suid \
    freerdp \
    freerdp-libs \
    fastfetch

# Clean package cache immediately to reduce layer size
# No longer using cache mounts, so must clean explicitly
echo "Cleaning DNF5 cache to reduce layer size..."
dnf5 clean all
rm -rf /var/cache/dnf5/*
