#!/usr/bin/bash
set -xeuo pipefail

# External repositories and COPR packages
# This layer changes moderately (~100MB, rebuilt when external packages updated)

# Install ublue-setup-services from COPR
dnf5 install --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:packages" -y \
    ublue-setup-services 2>&1 | grep -v "Failed to preset unit" || true

# Install packages from external repositories (COPRs)
# Following best practice: enable repo, install package, then disable repo
echo "Installing packages from external repositories..."

# CoolerControl - Hardware monitoring and control for AIOs/fan hubs
# Required for USB AIOs, liquid coolers, and fan hub support (requires liquidctl and lm_sensors)
# https://docs.coolercontrol.org/hardware-support.html
dnf5 copr enable -y codifryed/CoolerControl
dnf5 install -y coolercontrol || {
    echo "::warning::CoolerControl installation failed, continuing..."
}
dnf5 config-manager setopt "copr:copr.fedorainfracloud.org:codifryed:CoolerControl.enabled=0"

# Ghostty - Modern GPU-accelerated terminal emulator
dnf5 copr enable -y scottames/ghostty
dnf5 install -y ghostty || {
    echo "::warning::Ghostty installation failed, continuing..."
}
dnf5 config-manager setopt "copr:copr.fedorainfracloud.org:scottames:ghostty.enabled=0"

# Adding repositories should be a LAST RESORT. Contributing to Terra or `ublue-os/packages` is much preferred
# over using random coprs. Please keep this in mind when adding external dependencies.
# If adding any dependency, make sure to always have it disabled by default and _only_ enable it on `dnf install`

# Configure VS Code repository and import Microsoft GPG key
rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf5 config-manager addrepo --set=baseurl="https://packages.microsoft.com/yumrepos/vscode" --id="vscode"
dnf5 config-manager setopt vscode.enabled=0
# GPG verification now enabled with proper key import
dnf5 config-manager setopt vscode.gpgcheck=1
dnf5 install --enable-repo="vscode" -y \
    code

docker_pkgs=(
    containerd.io
    docker-buildx-plugin
    docker-ce
    docker-ce-cli
    docker-compose-plugin
)
dnf5 config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 install -y --enable-repo="docker-ce-stable" "${docker_pkgs[@]}" || {
    # Use test packages if docker pkgs is not available for f42
    if (($(lsb_release -sr) == 42)); then
        echo "::info::Missing docker packages in f42, falling back to test repos..."
        dnf5 install -y --enablerepo="docker-ce-test" "${docker_pkgs[@]}"
    fi
}

# Load iptable_nat module for docker-in-docker.
# See:
#   - https://github.com/ublue-os/bluefin/issues/2365
#   - https://github.com/devcontainers/features/issues/1235
mkdir -p /etc/modules-load.d && cat >>/etc/modules-load.d/ip_tables.conf <<EOF
iptable_nat
EOF

# Install WinBoat for Windows app integration
echo "Installing WinBoat for Windows application support..."
WINBOAT_VERSION="0.8.7"
WINBOAT_RPM="winboat-${WINBOAT_VERSION}-x86_64.rpm"
WINBOAT_URL="https://github.com/TibixDev/winboat/releases/download/v${WINBOAT_VERSION}/${WINBOAT_RPM}"

# Create /var/opt/winboat directory for rpm-ostree compatibility
# /opt is a symlink to /var/opt in rpm-ostree
mkdir -p /var/opt/winboat

curl -L -o "/tmp/${WINBOAT_RPM}" "${WINBOAT_URL}" || {
    echo "::warning::Failed to download WinBoat, continuing..."
}

if [[ -f "/tmp/${WINBOAT_RPM}" ]]; then
    # Note: WinBoat does not provide GPG-signed RPMs
    # Warning "skipped OpenPGP checks for 1 package from repository: @commandline" is expected
    dnf5 install -y "/tmp/${WINBOAT_RPM}" || {
        echo "::warning::WinBoat installation failed, continuing..."
    }
    rm -f "/tmp/${WINBOAT_RPM}"
else
    echo "::warning::WinBoat RPM not found, skipping installation..."
fi

# NVIDIA Container Toolkit is pre-installed in base image (bazzite-nvidia-open)
# No need to install it again - CDI config generation available via ujust

# Clean package cache immediately to reduce layer size
# No longer using cache mounts, so must clean explicitly
echo "Cleaning DNF5 cache to reduce layer size..."
dnf5 clean all
rm -rf /var/cache/dnf5/*
