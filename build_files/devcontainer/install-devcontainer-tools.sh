#!/usr/bin/bash
set -xeuo pipefail

# Devcontainer tools for bazzite-ai (KDE variant)
# Simplified to only install packages available in standard Fedora 42

# Core development tools
dnf5 install -y \
    alsa-lib-devel \
    arch-install-scripts \
    autoconf \
    automake \
    bridge-utils \
    ccache cmake \
    curl \
    debootstrap \
    dislocker \
    dotnet-sdk-9.0 \
    ecryptfs-utils \
    fdupes \
    fuse-devel \
    fuse-dislocker \
    fuse3-devel \
    gcc gcc-c++ make \
    gh \
    git git-lfs \
    golang-bazil-fuse-devel \
    golang-bin \
    html2text \
    htop \
    jdupes \
    libtool \
    neovim \
    nodejs nodejs20 nodejs20-devel nodejs20-full-i18n nodejs20-npm npm \
    php \
    podman podman-compose podman-docker podman-remote \
    python3 python3-devel python3-pip python3-tkinter \
    rpm-sign \
    squashfuse \
    strace \
    sysstat \
    vim \
    wget \
    zsh \
    apptainer apptainer-suid

# Optional tools (install if available, skip if not)
dnf5 install -y \
    android-tools \
    qemu-kvm \
    restic rclone \
    || echo "Some optional packages not available, continuing..."

# VS Code CLI
dnf5 config-manager addrepo --set=baseurl="https://packages.microsoft.com/yumrepos/vscode" --id="vscode" || true
dnf5 config-manager setopt vscode.enabled=0 vscode.gpgcheck=0 || true
dnf5 install --nogpgcheck --enable-repo="vscode" -y code || echo "VS Code install skipped"

# Docker CE for container-in-container
docker_pkgs=(containerd.io docker-buildx-plugin docker-ce docker-ce-cli docker-compose-plugin)
dnf5 config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo" || true
dnf5 config-manager setopt docker-ce-stable.enabled=0 || true
dnf5 install -y --enable-repo="docker-ce-stable" "${docker_pkgs[@]}" || \
    dnf5 install -y --enable-repo="docker-ce-test" "${docker_pkgs[@]}" || \
    echo "Docker CE install skipped"

# iptable_nat for docker-in-docker
mkdir -p /etc/modules-load.d
echo "iptable_nat" >> /etc/modules-load.d/ip_tables.conf || true

# Install devcontainers CLI for container automation
npm install -g @devcontainers/cli || echo "devcontainers CLI install skipped"

# Install pixi.sh for package management
curl -fsSL https://pixi.sh/install.sh | bash -s -- --yes || echo "pixi install skipped"

# Claude Code CLI
curl -fsSL https://claude.ai/install.sh | bash || echo "Claude Code install skipped"

# Cleanup
dnf5 clean all || true
rm -rf /var/cache/dnf5 || true
