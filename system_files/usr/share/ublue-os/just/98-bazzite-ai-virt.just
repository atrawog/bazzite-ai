# vim: set ft=make :

# Toggle libvirtd virtualization service
[group("virtualization")]
toggle-libvirtd ACTION="":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    ACTION="{{ ACTION }}"
    ACTION_LOWER=${ACTION,,}
    SERVICE="libvirtd.service"

    # Get current state
    if systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
        current_enabled="enabled"
        status_pretty="${green}Enabled${normal}"
    else
        current_enabled="disabled"
        status_pretty="${red}Disabled${normal}"
    fi

    if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
        current_active="active"
        active_pretty="${green}Running${normal}"
    else
        current_active="inactive"
        active_pretty="${red}Stopped${normal}"
    fi

    # Check KVM kernel args
    KARGS=$(rpm-ostree kargs 2>/dev/null || echo "")
    if echo "$KARGS" | grep -q "kvm.ignore_msrs"; then
        kvm_args_status="${green}Enabled${normal}"
    else
        kvm_args_status="${yellow}Not configured${normal}"
    fi

    # Check libvirt group membership
    if groups | grep -q '\blibvirt\b'; then
        group_status="${green}Yes${normal}"
    else
        group_status="${yellow}No${normal}"
    fi

    # Handle status display
    if [[ $ACTION_LOWER == "status" ]]; then
        echo -e "${bold}Virtualization Status${normal}"
        echo ""
        echo -e "Libvirtd Service: $status_pretty ($active_pretty)"
        echo -e "KVM Kernel Args: $kvm_args_status"
        echo -e "User in libvirt group: $group_status"
        echo ""
        if [[ $current_active == "active" ]]; then
            echo "Virtual machines can be managed via virt-manager."
        fi
        if [[ $group_status == *"No"* ]]; then
            echo -e "${yellow}⚠️  Not in libvirt group - sudo required for VM management${normal}"
            echo "Logout/login or reboot to apply group changes."
        fi
        exit 0
    fi

    # Handle help display
    if [[ $ACTION_LOWER == "help" ]]; then
        echo "Usage: ujust toggle-libvirtd [enable|disable|status|help]"
        echo "Control the libvirtd virtualization service."
        echo ""
        echo "Examples:"
        echo "  ujust toggle-libvirtd status   # Show current status"
        echo "  ujust toggle-libvirtd enable   # Enable libvirtd"
        echo "  ujust toggle-libvirtd disable  # Disable libvirtd"
        exit 0
    fi

    # Interactive mode or direct action
    CHOICE=""
    if [[ -z $ACTION_LOWER ]]; then
        echo -e "${bold}Libvirtd Virtualization Service${normal}"
        echo ""
        echo -e "Current state: $status_pretty (service), $active_pretty (daemon)"
        echo -e "KVM kernel args: $kvm_args_status"
        echo ""
        CHOICE=$(ugum choose \
            "Enable Libvirtd" \
            "Disable Libvirtd" \
            "Exit without changes")
    else
        case "$ACTION_LOWER" in
            enable) CHOICE="Enable Libvirtd" ;;
            disable) CHOICE="Disable Libvirtd" ;;
            *) echo "Unrecognized action: $ACTION" ; exit 1 ;;
        esac
    fi

    case "$CHOICE" in
        "Enable Libvirtd")
            if [[ $current_enabled == "enabled" ]]; then
                echo "Libvirtd is already enabled."
                exit 0
            fi

            echo "Enabling libvirtd service..."
            sudo systemctl enable "$SERVICE"
            sudo systemctl start "$SERVICE"

            echo ""
            echo -e "${green}${bold}✓ Libvirtd enabled${normal}"
            echo ""
            echo "You can now create virtual machines using virt-manager."
            ;;

        "Disable Libvirtd")
            if [[ $current_enabled == "disabled" ]]; then
                echo "Libvirtd is already disabled."
                exit 0
            fi

            echo ""
            echo -e "${yellow}⚠️  Warning${normal}"
            echo "Disabling libvirtd will stop all running VMs."
            echo ""
            read -p "Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Aborted."
                exit 1
            fi

            echo "Disabling libvirtd service..."
            sudo systemctl stop "$SERVICE"
            sudo systemctl disable "$SERVICE"

            echo ""
            echo -e "${green}${bold}✓ Libvirtd disabled${normal}"
            ;;

        "Exit without changes"|"")
            echo "No changes made."
            exit 0
            ;;
        *)
            echo "Unknown selection: $CHOICE" >&2
            exit 1
            ;;
    esac

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
