#!/usr/bin/bash
set -xeuo pipefail

# Install NVIDIA ML libraries for bazzite-ai-container-nvidia
# These libraries work with host CUDA runtime via nvidia-container-toolkit

echo "Installing NVIDIA ML libraries (cuDNN, TensorRT)..."

# Add negativo17 repository for cuDNN
# This repo provides well-maintained CUDA ecosystem packages for Fedora
dnf5 config-manager addrepo \
    --id="negativo17-nvidia" \
    --set=name="negativo17 - NVIDIA" \
    --set=baseurl="https://negativo17.org/repos/nvidia/fedora-\$releasever/\$basearch/" \
    --set=enabled=0 \
    --set=gpgcheck=1 \
    --set=gpgkey="https://negativo17.org/repos/RPM-GPG-KEY-slaanesh"

# Import GPG key
rpm --import https://negativo17.org/repos/RPM-GPG-KEY-slaanesh || true

# Install cuDNN from negativo17
# Note: Version depends on CUDA version on host (will be auto-matched)
dnf5 install -y --enable-repo="negativo17-nvidia" \
    cuda-cudnn || {
        echo "::warning::cuDNN installation failed - trying alternative method..."
        # Fallback: Try installing via Python wheels
        pip3 install --user nvidia-cudnn-cu12 || echo "::warning::cuDNN fallback also failed"
    }

# Install TensorRT
# TensorRT is best installed via Python wheels for containerized environments
echo "Installing TensorRT via Python wheels..."
pip3 install --user nvidia-tensorrt || {
    echo "::warning::TensorRT installation failed, continuing..."
}

# Install additional NVIDIA Python tools
pip3 install --user \
    nvidia-cuda-runtime-cu12 \
    nvidia-nvtx-cu12 \
    nvidia-nvjitlink-cu12 \
    || echo "::warning::Some NVIDIA Python packages failed to install"

# Verify installations
echo "Verifying NVIDIA library installations..."

if python3 -c "import tensorrt" 2>/dev/null; then
    echo "✓ TensorRT installed successfully"
    python3 -c "import tensorrt; print(f'TensorRT version: {tensorrt.__version__}')"
else
    echo "::warning::TensorRT verification failed"
fi

if python3 -c "import nvidia.cudnn" 2>/dev/null; then
    echo "✓ cuDNN installed successfully"
else
    echo "::warning::cuDNN verification failed (may still work via host CUDA)"
fi

echo "NVIDIA ML library installation complete"
