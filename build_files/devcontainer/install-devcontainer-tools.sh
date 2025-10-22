#!/usr/bin/bash
set -xeuo pipefail

# Devcontainer tools for bazzite-ai (KDE variant)
# Based on build_files/20-install-apps.sh

dnf5 install -y \
    android-tools \
    bcc bpftop bpftrace \
    ccache cmake \
    flatpak-builder \
    gcc gcc-c++ make \
    git vim neovim \
    nicstat numactl \
    nodejs npm \
    podman podman-docker podman-tui \
    python3 python3-pip python3-ramalama \
    qemu-kvm \
    restic rclone \
    sysprof tiptop \
    usbmuxd \
    zsh

# VS Code CLI
dnf5 config-manager addrepo --set=baseurl="https://packages.microsoft.com/yumrepos/vscode" --id="vscode"
dnf5 config-manager setopt vscode.enabled=0 vscode.gpgcheck=0
dnf5 install --nogpgcheck --enable-repo="vscode" -y code

# Docker CE for container-in-container
docker_pkgs=(containerd.io docker-buildx-plugin docker-ce docker-ce-cli docker-compose-plugin)
dnf5 config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 install -y --enable-repo="docker-ce-stable" "${docker_pkgs[@]}" || \
    dnf5 install -y --enable-repo="docker-ce-test" "${docker_pkgs[@]}"

# iptable_nat for docker-in-docker
mkdir -p /etc/modules-load.d
echo "iptable_nat" >> /etc/modules-load.d/ip_tables.conf

# Claude Code CLI
curl -fsSL https://claude.ai/install.sh | bash || echo "Claude Code install skipped"

# Cleanup
dnf5 clean all
rm -rf /var/cache/dnf5
