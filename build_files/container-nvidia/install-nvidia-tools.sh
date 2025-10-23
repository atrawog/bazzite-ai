#!/usr/bin/bash
set -xeuo pipefail

# Install NVIDIA ML libraries for bazzite-ai-container-nvidia
# These libraries work with host CUDA runtime via nvidia-container-toolkit

echo "Installing NVIDIA ML libraries (cuDNN, TensorRT)..."

# Add negativo17 multimedia repository for cuDNN
# CUDA packages moved to multimedia repo in Fedora 42
dnf5 config-manager addrepo \
    --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo"
dnf5 config-manager setopt "fedora-multimedia.enabled=0"

# Import GPG key
rpm --import https://negativo17.org/repos/RPM-GPG-KEY-slaanesh || true

# Try installing cuDNN from repository first
dnf5 install -y --enable-repo="fedora-multimedia" cuda-cudnn || {
    echo "::warning::cuDNN not available in repository - using Python wheels..."
    # Fallback: Install via Python wheels
    pip3 install --root-user-action=ignore nvidia-cudnn-cu12 || \
        echo "::warning::cuDNN installation failed"
}

# Install TensorRT via Python wheels (not available in repos)
echo "Installing TensorRT via Python wheels..."
pip3 install --root-user-action=ignore nvidia-tensorrt || {
    echo "::warning::TensorRT installation failed, continuing..."
}

# Install additional NVIDIA Python tools
pip3 install --root-user-action=ignore \
    nvidia-cuda-runtime-cu12 \
    nvidia-nvtx-cu12 \
    nvidia-nvjitlink-cu12 \
    || echo "::warning::Some NVIDIA Python packages failed to install"

# Clean dnf cache to reduce layer size and avoid buildah commit issues
dnf5 clean all
rm -rf /var/cache/dnf5/* || true

# Verify installations
echo "Verifying NVIDIA library installations..."

if python3 -c "import tensorrt" 2>/dev/null; then
    echo "✓ TensorRT installed successfully"
    python3 -c "import tensorrt; print(f'TensorRT version: {tensorrt.__version__}')" || true
else
    echo "::warning::TensorRT verification failed"
fi

if python3 -c "import nvidia.cudnn" 2>/dev/null; then
    echo "✓ cuDNN installed successfully"
else
    echo "::warning::cuDNN verification failed (may still work via host CUDA)"
fi

echo "NVIDIA ML library installation complete"
