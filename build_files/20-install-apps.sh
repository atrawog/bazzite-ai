#!/usr/bin/bash
set -xeuo pipefail

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
    coolercontrol \
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
    ghostty \
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
    nicstat \
    nodejs20 \
    nodejs20-devel \
    nodejs20-full-i18n \
    nodejs20-npm \
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
    usbmuxd \
    vlc \
    wireshark \
    xorg-x11-server-devel \
    xorg-x11-server-Xorg \
    zsh

# Restore UUPD update timer and Input Remapper
sed -i 's@^NoDisplay=true@NoDisplay=false@' /usr/share/applications/input-remapper-gtk.desktop
systemctl enable input-remapper.service
systemctl enable uupd.timer

# Remove -deck specific changes to allow for login screens
rm -f /etc/sddm.conf.d/steamos.conf
rm -f /etc/sddm.conf.d/virtualkbd.conf
rm -f /usr/share/gamescope-session-plus/bootstrap_steam.tar.gz
systemctl disable bazzite-autologin.service

if [[ "$IMAGE_NAME" == *gnome* ]]; then
    # Remove SDDM and re-enable GDM on GNOME builds.
    dnf5 remove -y \
        sddm

    systemctl enable gdm.service
else
    # Re-enable logout and switch user functionality in KDE
    sed -i -E \
      -e 's/^(action\/switch_user)=false/\1=true/' \
      -e 's/^(action\/start_new_session)=false/\1=true/' \
      -e 's/^(action\/lock_screen)=false/\1=true/' \
      -e 's/^(kcm_sddm\.desktop)=false/\1=true/' \
      -e 's/^(kcm_plymouth\.desktop)=false/\1=true/' \
      /etc/xdg/kdeglobals
fi


dnf5 install --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:packages" -y \
    ublue-setup-services

# Adding repositories should be a LAST RESORT. Contributing to Terra or `ublue-os/packages` is much preferred
# over using random coprs. Please keep this in mind when adding external dependencies.
# If adding any dependency, make sure to always have it disabled by default and _only_ enable it on `dnf install`

dnf5 config-manager addrepo --set=baseurl="https://packages.microsoft.com/yumrepos/vscode" --id="vscode"
dnf5 config-manager setopt vscode.enabled=0
# FIXME: gpgcheck is broken for vscode due to it using `asc` for checking
# seems to be broken on newer rpm security policies.
dnf5 config-manager setopt vscode.gpgcheck=0
dnf5 install --nogpgcheck --enable-repo="vscode" -y \
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

# Install devcontainers CLI for container development automation
# Requires Node.js, Python, and C/C++ compiler (already installed above)
echo "Installing devcontainers CLI..."
npm install -g @devcontainers/cli || {
    echo "::warning::devcontainers CLI installation failed, continuing..."
}

# Install pixi.sh - Modern package/project manager for conda ecosystem
echo "Installing pixi.sh for package management..."
export PIXI_HOME=/usr/local/pixi
curl -fsSL https://pixi.sh/install.sh | bash -s -- --yes || {
    echo "::warning::pixi installation failed, continuing..."
}
# Ensure pixi is in system PATH
if [ -f "$PIXI_HOME/bin/pixi" ]; then
    ln -sf "$PIXI_HOME/bin/pixi" /usr/local/bin/pixi
    echo "pixi installed to /usr/local/bin/pixi"
fi

# Install NVIDIA Container Toolkit for GPU-enabled containers
# Only for nvidia variants (KDE only - bazzite-ai only supports KDE)
if [[ "$IMAGE_NAME" == *nvidia* ]]; then
    echo "Installing NVIDIA Container Toolkit for GPU container support..."

    # Fedora 42 official package: golang-github-nvidia-container-toolkit v1.17.4
    # Fallback to COPR if unavailable
    dnf5 install -y nvidia-container-toolkit || {
        echo "::info::Falling back to COPR for nvidia-container-toolkit"
        dnf5 copr enable -y @ai-ml/nvidia-container-toolkit
        dnf5 install -y nvidia-container-toolkit
    }

    echo "NVIDIA Container Toolkit installed. CDI config generation available via ujust."
fi
