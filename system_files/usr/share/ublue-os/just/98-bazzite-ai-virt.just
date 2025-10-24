# vim: set ft=make :

# Pull bazzite-ai-container-nvidia using Apptainer
[group("virtualization")]
apptainer-pull-container-nvidia tag="latest":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    TAG="{{ tag }}"
    OUTPUT_NAME="bazzite-ai-container-nvidia_${TAG}.sif"

    echo -e "${bold}Pulling bazzite-ai-container-nvidia via Apptainer${normal}"
    echo "Registry: ghcr.io/atrawog/bazzite-ai-container-nvidia:${TAG}"
    echo "Output: $HOME/${OUTPUT_NAME}"
    echo ""

    cd "$HOME"
    apptainer pull "docker://ghcr.io/atrawog/bazzite-ai-container-nvidia:${TAG}"

    echo ""
    echo -e "${green}${bold}✓ Success${normal}"
    echo "Container saved: $HOME/${OUTPUT_NAME}"
    echo ""
    echo "Run with:"
    echo "  ujust apptainer-run-container-nvidia"

# Pull bazzite-ai-container (base, CPU-only) using Apptainer
[group("virtualization")]
apptainer-pull-container tag="latest":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    TAG="{{ tag }}"
    OUTPUT_NAME="bazzite-ai-container_${TAG}.sif"

    echo -e "${bold}Pulling bazzite-ai-container (base, CPU-only) via Apptainer${normal}"
    echo "Registry: ghcr.io/atrawog/bazzite-ai-container:${TAG}"
    echo "Output: $HOME/${OUTPUT_NAME}"
    echo ""

    cd "$HOME"
    apptainer pull "docker://ghcr.io/atrawog/bazzite-ai-container:${TAG}"

    echo ""
    echo -e "${green}${bold}✓ Success${normal}"
    echo "Container saved: $HOME/${OUTPUT_NAME}"
    echo ""
    echo "Run with:"
    echo "  ujust apptainer-run-container"

# Run bazzite-ai-container-nvidia with Apptainer (GPU enabled)
[group("virtualization")]
apptainer-run-container-nvidia tag="latest" workspace="":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    TAG="{{ tag }}"
    WORKSPACE="{{ workspace }}"
    SIF_FILE="$HOME/bazzite-ai-container-nvidia_${TAG}.sif"

    # Default workspace to current directory
    if [[ -z "${WORKSPACE}" ]]; then
        WORKSPACE="$(pwd)"
    fi

    # Check if container exists
    if [[ ! -f "${SIF_FILE}" ]]; then
        echo -e "${yellow}Container not found: ${SIF_FILE}${normal}"
        echo "Pulling from GHCR..."
        just apptainer-pull-container-nvidia "${TAG}"
    fi

    echo -e "${bold}Starting bazzite-ai-container-nvidia${normal}"
    echo "Workspace: ${WORKSPACE}"
    echo ""

    # Check for GPU
    if command -v nvidia-smi &> /dev/null; then
        echo -e "${green}✓ NVIDIA GPU detected - enabling GPU support${normal}"
        GPU_FLAG="--nv"
    else
        echo "No GPU detected - running in CPU-only mode"
        GPU_FLAG=""
    fi

    echo ""
    echo "Starting interactive shell..."

    # Run with GPU support, writable tmpfs, and workspace bind
    apptainer shell \
        ${GPU_FLAG} \
        --writable-tmpfs \
        --bind "${WORKSPACE}:/workspace" \
        --pwd /workspace \
        "${SIF_FILE}"

# Run bazzite-ai-container with Apptainer (base, CPU only)
[group("virtualization")]
apptainer-run-container tag="latest" workspace="":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    TAG="{{ tag }}"
    WORKSPACE="{{ workspace }}"
    SIF_FILE="$HOME/bazzite-ai-container_${TAG}.sif"

    if [[ -z "${WORKSPACE}" ]]; then
        WORKSPACE="$(pwd)"
    fi

    if [[ ! -f "${SIF_FILE}" ]]; then
        echo "Pulling container..."
        just apptainer-pull-container "${TAG}"
    fi

    echo -e "${bold}Starting bazzite-ai-container (base, CPU-only)${normal}"

    apptainer shell \
        --writable-tmpfs \
        --bind "${WORKSPACE}:/workspace" \
        --pwd /workspace \
        "${SIF_FILE}"

# Execute command in bazzite-ai-container-nvidia via Apptainer
[group("virtualization")]
apptainer-exec-container-nvidia cmd tag="latest" workspace="":
    #!/usr/bin/bash
    set -euo pipefail

    TAG="{{ tag }}"
    CMD="{{ cmd }}"
    WORKSPACE="{{ workspace }}"
    SIF_FILE="$HOME/bazzite-ai-container-nvidia_${TAG}.sif"

    if [[ -z "${WORKSPACE}" ]]; then
        WORKSPACE="$(pwd)"
    fi

    if [[ ! -f "${SIF_FILE}" ]]; then
        echo "Container not found. Run: ujust apptainer-pull-container-nvidia"
        exit 1
    fi

    if command -v nvidia-smi &> /dev/null; then
        GPU_FLAG="--nv"
    else
        GPU_FLAG=""
    fi

    apptainer exec \
        ${GPU_FLAG} \
        --writable-tmpfs \
        --bind "${WORKSPACE}:/workspace" \
        --pwd /workspace \
        "${SIF_FILE}" \
        ${CMD}

# Show Apptainer setup information
[group("virtualization")]
apptainer-info:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Apptainer Container Platform${normal}"
    echo "HPC and scientific computing optimized"
    echo ""
    apptainer version
    echo ""

    if command -v nvidia-smi &> /dev/null; then
        echo -e "${green}✓ NVIDIA GPU detected${normal}"
        echo "Use --nv flag for GPU support"
    else
        echo "No NVIDIA GPU detected (CPU-only mode available)"
    fi

    echo ""
    echo -e "${bold}Quick Start:${normal}"
    echo "  # GPU Development (NVIDIA)"
    echo "  ujust apptainer-pull-container-nvidia   # Download NVIDIA container"
    echo "  ujust apptainer-run-container-nvidia    # Interactive shell with GPU"
    echo ""
    echo "  # CPU-Only Development"
    echo "  ujust apptainer-pull-container          # Download base container"
    echo "  ujust apptainer-run-container           # Interactive shell (CPU)"
    echo ""
    echo "Documentation: https://apptainer.org/docs/"

# Launch WinBoat for Windows app integration
[group("virtualization")]
winboat-launch:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Launching WinBoat${normal}"
    echo "Windows app integration platform"
    echo ""

    if ! command -v winboat &> /dev/null; then
        echo -e "${red}${bold}Error:${normal} WinBoat not installed"
        echo "WinBoat should be pre-installed in bazzite-ai"
        exit 1
    fi

    # Check Docker is running
    if ! systemctl is-active --quiet docker; then
        echo "Starting Docker service..."
        sudo systemctl start docker
    fi

    winboat

# Show WinBoat information
[group("virtualization")]
winboat-info:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}WinBoat - Windows App Integration${normal}"
    echo "Run Windows applications with seamless Linux integration"
    echo ""

    if command -v winboat &> /dev/null; then
        echo -e "${green}✓ WinBoat installed${normal}"
    else
        echo -e "${red}✗ WinBoat not installed${normal}"
        exit 1
    fi

    if command -v xfreerdp &> /dev/null; then
        echo -e "${green}✓ FreeRDP installed${normal}"
        xfreerdp --version | head -1
    else
        echo -e "${red}✗ FreeRDP not installed${normal}"
    fi

    if systemctl is-active --quiet docker; then
        echo -e "${green}✓ Docker running${normal}"
    else
        echo -e "${yellow}⚠ Docker not running${normal}"
        echo "Start with: sudo systemctl start docker"
    fi

    echo ""
    echo "Usage:"
    echo "  ujust winboat-launch    # Start WinBoat GUI"
    echo "  winboat                 # Direct command"
    echo ""
    echo "Documentation:"
    echo "  https://github.com/TibixDev/winboat"
