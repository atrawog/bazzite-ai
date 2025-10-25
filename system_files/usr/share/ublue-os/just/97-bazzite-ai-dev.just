# vim: set ft=make :

# Setup GPU access for containers (pre-installed on all bazzite-ai)
[group("development")]
setup-gpu-containers:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    # Check if nvidia-container-toolkit is installed
    if ! command -v nvidia-ctk &> /dev/null; then
        echo -e "${red}${bold}Error:${normal} nvidia-container-toolkit not found."
        echo "nvidia-container-toolkit should be pre-installed on bazzite-ai."
        echo "Please file a bug report if you're seeing this message."
        exit 1
    fi

    # Check for NVIDIA GPU
    if ! lspci | grep -i nvidia &> /dev/null; then
        echo -e "${yellow}${bold}Warning:${normal} No NVIDIA GPU detected."
        echo "CDI configuration will still be generated but may not work."
    fi

    echo "Generating CDI configuration for GPU container access..."

    # Generate CDI specification for Podman GPU passthrough
    if [[ $EUID -ne 0 ]]; then
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    else
        nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    fi

    echo -e "${green}${bold}Success:${normal} CDI configuration at /etc/cdi/nvidia.yaml"
    echo ""
    echo "GPU-accelerated containers now available:"
    echo "  podman run --device nvidia.com/gpu=all <image>"
    echo "  just run-devcontainer"
    echo ""
    echo "Test GPU access:"
    echo "  just test-cuda-devcontainer"

# Install or update Claude Code CLI
[group("development")]
install-claude-code:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Claude Code CLI${normal}"
    echo "Location: $HOME/.local/bin/claude"
    echo ""

    # Run official installer
    if curl -fsSL https://claude.ai/install.sh | bash; then
        echo ""
        if command -v claude &> /dev/null; then
            echo -e "${green}${bold}✓ Success:${normal} Claude Code installed"
            claude --version
            echo ""
            echo -e "${bold}Auto-updates:${normal} Enabled by default"
            echo "Claude Code checks for updates on startup"
            echo ""

            # Add Claude CLI aliases
            echo "Setting up Claude CLI aliases..."
            ALIAS_FILE="$HOME/.bash_aliases"

            # Create or update .bash_aliases with Claude aliases
            if ! grep -q "# Claude CLI aliases" "$ALIAS_FILE" 2>/dev/null; then
                {
                    echo ""
                    echo "# Claude CLI aliases"
                    echo "alias cl='claude'"
                    echo "alias clc='claude --continue'"
                    echo "alias cld='claude --dangerously-skip-permissions'"
                    echo "alias cldc='claude --dangerously-skip-permissions --continue'"
                } >> "$ALIAS_FILE"

                # Ensure .bashrc sources .bash_aliases
                if ! grep -q ".bash_aliases" "$HOME/.bashrc" 2>/dev/null; then
                    {
                        echo ""
                        echo "# Source aliases"
                        echo "if [ -f ~/.bash_aliases ]; then"
                        echo "    . ~/.bash_aliases"
                        echo "fi"
                    } >> "$HOME/.bashrc"
                fi

                echo -e "${green}✓ Aliases added to $ALIAS_FILE${normal}"
            else
                echo -e "${green}✓ Aliases already configured${normal}"
            fi

            echo ""
            echo -e "${bold}Available aliases:${normal}"
            echo "  cl      → claude"
            echo "  clc     → claude --continue"
            echo "  cld     → claude --dangerously-skip-permissions"
            echo "  cldc    → claude --dangerously-skip-permissions --continue"
            echo ""
            echo -e "${yellow}${bold}⚠ Action Required:${normal} Aliases are configured but not yet active in this shell."
            echo ""
            echo "To activate aliases immediately, run:"
            echo -e "${bold}  source ~/.bashrc${normal}"
            echo ""
            echo "Or open a new terminal window."
        else
            echo -e "${yellow}${bold}Warning:${normal} Installation completed but 'claude' not in PATH"
            echo "You may need to restart your shell or add ~/.local/bin to PATH"
        fi
    else
        echo -e "${red}${bold}✗ Error:${normal} Claude Code installation failed"
        exit 1
    fi

# Check Claude Code installation and auto-update status
[group("development")]
check-claude-code:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Claude Code Status${normal}"
    echo ""

    if command -v claude &> /dev/null; then
        echo -e "${green}✓ Installed${normal}"
        echo "Version: $(claude --version 2>&1 | head -1)"
        echo "Location: $(which claude)"
        echo ""
        echo -e "${bold}Auto-update:${normal} Enabled"
        echo "Claude Code automatically checks for updates on each run"
        echo ""
        echo "To update: Run any claude command (updates check automatically)"
    else
        echo -e "${red}✗ Not installed${normal}"
        echo ""
        echo "To install: ujust install-claude-code"
        exit 1
    fi

# Install pixi package manager
[group("development")]
install-pixi:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing pixi.sh${normal}"
    echo "Modern package manager for conda ecosystem"
    echo "Location: $HOME/.pixi/bin/pixi"
    echo ""

    # Check if already installed
    if command -v pixi &> /dev/null; then
        echo -e "${green}✓ pixi already installed${normal}"
        pixi --version
        echo ""
        echo "To update: pixi self-update"
        exit 0
    fi

    # Install to user home directory
    export PIXI_HOME="$HOME/.pixi"
    curl -fsSL https://pixi.sh/install.sh | bash -s -- --yes

    if [ -f "$PIXI_HOME/bin/pixi" ]; then
        echo ""
        echo -e "${green}${bold}✓ Success:${normal} pixi installed"
        "$PIXI_HOME/bin/pixi" --version
        echo ""
        echo -e "${bold}Usage:${normal}"
        echo "  pixi --help"
        echo "  pixi init my-project"
        echo ""
        echo -e "${yellow}Note:${normal} Restart your shell or run: source ~/.bashrc"
    else
        echo -e "${red}${bold}✗ Error:${normal} Installation failed"
        exit 1
    fi

# Install devcontainers CLI
[group("development")]
install-devcontainers-cli:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing devcontainers CLI${normal}"
    echo "Container development automation tool"
    echo ""

    # Check if already installed (check both PATH and direct location)
    if command -v devcontainer &> /dev/null || [ -x "$HOME/.npm-global/bin/devcontainer" ]; then
        echo -e "${green}✓ devcontainer already installed${normal}"
        if command -v devcontainer &> /dev/null; then
            devcontainer --version
        else
            "$HOME/.npm-global/bin/devcontainer" --version
        fi
        echo ""
        echo "To update: npm update -g @devcontainers/cli"
        exit 0
    fi

    # Configure npm to use user directory if not already set
    if [ "$(npm config get prefix)" = "/usr" ] || [ "$(npm config get prefix)" = "/usr/local" ]; then
        echo "Configuring npm to use user directory..."
        npm config set prefix "$HOME/.npm-global"

        # Add to PATH if not already there
        if ! grep -q ".npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
        fi
    fi

    # Install devcontainers CLI
    echo "Installing @devcontainers/cli..."
    npm install -g @devcontainers/cli

    # Update PATH in current shell for verification
    export PATH="$HOME/.npm-global/bin:$PATH"

    if command -v devcontainer &> /dev/null; then
        echo ""
        echo -e "${green}${bold}✓ Success:${normal} devcontainers CLI installed"
        devcontainer --version
        echo ""
        echo -e "${bold}Usage:${normal}"
        echo "  devcontainer --help"
        echo "  devcontainer build --workspace-folder ."
        echo ""
        echo -e "${yellow}Note:${normal} Restart your shell or run: source ~/.bashrc"
    else
        echo -e "${red}${bold}✗ Error:${normal} Installation failed"
        echo "You may need to add ~/.npm-global/bin to your PATH"
        exit 1
    fi

# Install LM Studio (local LLM runtime)
[group("development")]
install-lmstudio:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing LM Studio${normal}"
    echo "Local LLM runtime with GUI and server modes"
    echo ""

    # Check if already installed
    if [ -x "$HOME/.local/bin/lmstudio/LM_Studio.AppImage" ]; then
        echo -e "${green}✓ LM Studio already installed${normal}"
        echo "Location: $HOME/.local/bin/lmstudio/"
        echo ""
        echo "To reinstall, remove the directory first:"
        echo "  rm -rf ~/.local/bin/lmstudio"
        exit 0
    fi

    LMSTUDIO_VERSION="0.3.30"
    INSTALL_DIR="$HOME/.local/bin/lmstudio"
    APPIMAGE_URL="https://releases.lmstudio.ai/linux/x86/${LMSTUDIO_VERSION}/LM_Studio-${LMSTUDIO_VERSION}.AppImage"

    echo "Downloading LM Studio ${LMSTUDIO_VERSION}..."
    echo "This may take a few minutes (AppImage is ~500MB)"
    echo ""

    # Create install directory
    mkdir -p "${INSTALL_DIR}"

    # Download AppImage
    if ! curl -fL --progress-bar -o "${INSTALL_DIR}/LM_Studio.AppImage" "${APPIMAGE_URL}"; then
        echo ""
        echo -e "${red}${bold}✗ Error:${normal} Download failed"
        echo "URL: ${APPIMAGE_URL}"
        echo ""
        echo "Try manual installation:"
        echo "  1. Download from: https://lmstudio.ai/download"
        echo "  2. Place AppImage at: ${INSTALL_DIR}/LM_Studio.AppImage"
        echo "  3. Run: chmod +x ${INSTALL_DIR}/LM_Studio.AppImage"
        rm -rf "${INSTALL_DIR}"
        exit 1
    fi

    # Make executable
    chmod +x "${INSTALL_DIR}/LM_Studio.AppImage"

    # Create symlink for easy access
    ln -sf "${INSTALL_DIR}/LM_Studio.AppImage" "$HOME/.local/bin/lmstudio"

    # Add ~/.lmstudio/bin to PATH for lms CLI (will be created on first run)
    if ! grep -q ".lmstudio/bin" "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.lmstudio/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    echo ""
    echo -e "${green}${bold}✓ Success:${normal} LM Studio installed"
    echo ""
    echo -e "${bold}Installation:${normal}"
    echo "  AppImage: ${INSTALL_DIR}/LM_Studio.AppImage"
    echo "  Symlink: $HOME/.local/bin/lmstudio"
    echo "  Models: ~/.cache/lmstudio (created on first run)"
    echo ""
    echo -e "${bold}Usage:${normal}"
    echo "  lmstudio                           # Launch GUI"
    echo "  ujust toggle-lmstudio-gui enable   # Auto-start GUI at boot"
    echo "  ujust toggle-lmstudio-server enable # Auto-start server at boot"
    echo "  ujust check-lmstudio               # Check installation status"
    echo ""
    echo -e "${yellow}Note:${normal} CLI tools (~/.lmstudio/bin/lms) will be available after first GUI launch"
    echo "      Restart your shell or run: source ~/.bashrc"

# Check LM Studio installation and service status
[group("development")]
check-lmstudio:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}LM Studio Status${normal}"
    echo ""

    # Check AppImage installation
    if [ -x "$HOME/.local/bin/lmstudio/LM_Studio.AppImage" ]; then
        echo -e "${green}✓ AppImage installed${normal}"
        echo "  Location: $HOME/.local/bin/lmstudio/LM_Studio.AppImage"

        # Try to get version (AppImage might not support --version)
        if [ -L "$HOME/.local/bin/lmstudio" ]; then
            echo "  Symlink: $HOME/.local/bin/lmstudio → LM_Studio.AppImage"
        fi
    else
        echo -e "${red}✗ AppImage not installed${normal}"
        echo "  Install with: ujust install-lmstudio"
        exit 1
    fi

    echo ""

    # Check CLI tools
    if [ -x "$HOME/.lmstudio/bin/lms" ]; then
        echo -e "${green}✓ CLI tools available${normal}"
        echo "  Location: $HOME/.lmstudio/bin/lms"
    else
        echo -e "${yellow}⚠ CLI tools not initialized${normal}"
        echo "  Run 'lmstudio' once to initialize CLI tools"
    fi

    echo ""

    # Check GUI service status
    if systemctl --user is-enabled --quiet lmstudio-gui.service 2>/dev/null; then
        gui_enabled="${green}Enabled${normal}"
    else
        gui_enabled="${red}Disabled${normal}"
    fi

    if systemctl --user is-active --quiet lmstudio-gui.service 2>/dev/null; then
        gui_active="${green}Running${normal}"
    else
        gui_active="${red}Stopped${normal}"
    fi

    echo -e "${bold}GUI Service:${normal} $gui_enabled, $gui_active"

    # Check Server service status
    if systemctl --user is-enabled --quiet lmstudio-server.service 2>/dev/null; then
        server_enabled="${green}Enabled${normal}"
    else
        server_enabled="${red}Disabled${normal}"
    fi

    if systemctl --user is-active --quiet lmstudio-server.service 2>/dev/null; then
        server_active="${green}Running${normal}"
    else
        server_active="${red}Stopped${normal}"
    fi

    echo -e "${bold}Server Service:${normal} $server_enabled, $server_active"

    echo ""

    # Check linger status
    linger_status=$(loginctl show-user "$USER" 2>/dev/null | grep "^Linger=" | cut -d= -f2 || echo "no")
    echo -e "${bold}Linger:${normal} $linger_status (required for boot persistence)"

    echo ""

    # Model cache location
    if [ -d "$HOME/.cache/lmstudio" ]; then
        cache_size=$(du -sh "$HOME/.cache/lmstudio" 2>/dev/null | cut -f1 || echo "unknown")
        echo -e "${bold}Model Cache:${normal} ~/.cache/lmstudio ($cache_size)"
    else
        echo -e "${bold}Model Cache:${normal} ~/.cache/lmstudio (not created yet)"
    fi

    echo ""
    echo -e "${bold}Server API:${normal} http://localhost:1234/v1/* (when server running)"

# Toggle LM Studio GUI mode (full application)
[group("development")]
toggle-lmstudio-gui ACTION="":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    ACTION="{{ ACTION }}"
    ACTION_LOWER=${ACTION,,}
    SERVICE="lmstudio-gui.service"

    # Check if LM Studio is installed
    if [ ! -x "$HOME/.local/bin/lmstudio/LM_Studio.AppImage" ]; then
        echo -e "${red}${bold}Error:${normal} LM Studio not installed"
        echo "Install with: ujust install-lmstudio"
        exit 1
    fi

    # Get current service state
    if systemctl --user is-enabled --quiet "$SERVICE" 2>/dev/null; then
        service_enabled="enabled"
        status_pretty="${green}Enabled${normal}"
    else
        service_enabled="disabled"
        status_pretty="${red}Disabled${normal}"
    fi

    if systemctl --user is-active --quiet "$SERVICE" 2>/dev/null; then
        service_active="active"
        active_pretty="${green}Running${normal}"
    else
        service_active="inactive"
        active_pretty="${red}Stopped${normal}"
    fi

    # Check linger status
    linger_status=$(loginctl show-user "$USER" 2>/dev/null | grep "^Linger=" | cut -d= -f2 || echo "no")

    # Handle status display
    if [[ $ACTION_LOWER == "status" ]]; then
        echo -e "${bold}LM Studio GUI Service Status${normal}"
        echo ""
        echo -e "Service: ${bold}$SERVICE${normal} (user service)"
        echo -e "Enabled: $status_pretty"
        echo -e "Active: $active_pretty"
        echo -e "Linger: $linger_status"
        echo ""
        if [[ $service_active == "active" ]]; then
            echo "LM Studio GUI is running"
            echo ""
            echo "Check logs:"
            echo "  systemctl --user status lmstudio-gui.service"
            echo "  journalctl --user -u lmstudio-gui.service"
        fi
        exit 0
    fi

    # Handle help display
    if [[ $ACTION_LOWER == "help" ]]; then
        echo "Usage: ujust toggle-lmstudio-gui [enable|disable|status|help]"
        echo "If no action is provided you'll be prompted with a picker."
        echo ""
        echo "Manages LM Studio GUI as a systemd user service."
        echo "Linger must be enabled for service to start at boot (before login)."
        exit 0
    fi

    # Interactive mode or direct action
    CHOICE=""
    if [[ -z $ACTION_LOWER ]]; then
        echo -e "${bold}LM Studio GUI Service Configuration${normal}"
        echo ""
        echo -e "Service: $status_pretty, $active_pretty"
        echo -e "Linger: ${linger_status}"
        echo ""
        echo "Select action:"
        echo ""
        CHOICE=$(ugum choose \
            "Enable LM Studio GUI" \
            "Disable LM Studio GUI" \
            "Exit without changes")
    else
        case "$ACTION_LOWER" in
            enable) CHOICE="Enable LM Studio GUI" ;;
            disable) CHOICE="Disable LM Studio GUI" ;;
            *) echo "Unrecognized action: $ACTION" ; exit 1 ;;
        esac
    fi

    case "$CHOICE" in
        "Enable LM Studio GUI")
            if [[ $service_enabled == "enabled" && $linger_status == "yes" ]]; then
                echo "LM Studio GUI is already enabled with linger."
                exit 0
            fi

            # Create systemd user service directory if it doesn't exist
            mkdir -p "$HOME/.config/systemd/user"

            # Create service file
            cat > "$HOME/.config/systemd/user/$SERVICE" <<'EOF'
[Unit]
Description=LM Studio GUI
After=network.target

[Service]
Type=simple
ExecStart=%h/.local/bin/lmstudio/LM_Studio.AppImage --no-sandbox
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=default.target
EOF

            echo "Enabling LM Studio GUI service..."
            systemctl --user daemon-reload
            systemctl --user enable "$SERVICE"
            systemctl --user start "$SERVICE"

            # Enable linger for boot persistence
            if [[ $linger_status != "yes" ]]; then
                echo "Enabling linger for user $USER (required for boot persistence)..."
                loginctl enable-linger "$USER"
            fi

            echo ""
            echo -e "${green}${bold}✓ LM Studio GUI enabled${normal}"
            echo ""
            echo "Service will start at boot (before login)."
            echo ""
            echo "Next steps:"
            echo "  1. LM Studio GUI is now running"
            echo "  2. Download models through the GUI"
            echo "  3. Check status: ujust toggle-lmstudio-gui status"
            ;;

        "Disable LM Studio GUI")
            if [[ $service_enabled == "disabled" ]]; then
                echo "LM Studio GUI is already disabled."
                exit 0
            fi

            echo "Disabling LM Studio GUI service..."
            systemctl --user stop "$SERVICE"
            systemctl --user disable "$SERVICE"

            echo ""
            echo -e "${green}${bold}✓ LM Studio GUI disabled${normal}"
            echo ""
            echo "Service will no longer start at boot."

            # Warn about linger
            if [[ $linger_status == "yes" ]]; then
                echo ""
                echo -e "${yellow}Note:${normal} Linger is still enabled for user $USER."
                echo "This allows other user services to start at boot."
                echo "If you have no other services that need boot persistence,"
                echo "you can disable linger with:"
                echo "  loginctl disable-linger $USER"
            fi
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

# Toggle LM Studio server mode (API only, more efficient)
[group("development")]
toggle-lmstudio-server ACTION="":
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    ACTION="{{ ACTION }}"
    ACTION_LOWER=${ACTION,,}
    SERVICE="lmstudio-server.service"

    # Check if LM Studio is installed
    if [ ! -x "$HOME/.local/bin/lmstudio/LM_Studio.AppImage" ]; then
        echo -e "${red}${bold}Error:${normal} LM Studio not installed"
        echo "Install with: ujust install-lmstudio"
        exit 1
    fi

    # Check if CLI tools are initialized
    if [ ! -x "$HOME/.lmstudio/bin/lms" ]; then
        echo -e "${yellow}${bold}Warning:${normal} LM Studio CLI tools not initialized"
        echo ""
        echo "The 'lms' CLI is created on first GUI launch."
        echo "Please run 'lmstudio' once to initialize, then try again."
        echo ""
        echo "Alternatively, enable GUI mode which will initialize it:"
        echo "  ujust toggle-lmstudio-gui enable"
        exit 1
    fi

    # Get current service state
    if systemctl --user is-enabled --quiet "$SERVICE" 2>/dev/null; then
        service_enabled="enabled"
        status_pretty="${green}Enabled${normal}"
    else
        service_enabled="disabled"
        status_pretty="${red}Disabled${normal}"
    fi

    if systemctl --user is-active --quiet "$SERVICE" 2>/dev/null; then
        service_active="active"
        active_pretty="${green}Running${normal}"
    else
        service_active="inactive"
        active_pretty="${red}Stopped${normal}"
    fi

    # Check linger status
    linger_status=$(loginctl show-user "$USER" 2>/dev/null | grep "^Linger=" | cut -d= -f2 || echo "no")

    # Handle status display
    if [[ $ACTION_LOWER == "status" ]]; then
        echo -e "${bold}LM Studio Server Service Status${normal}"
        echo ""
        echo -e "Service: ${bold}$SERVICE${normal} (user service)"
        echo -e "Enabled: $status_pretty"
        echo -e "Active: $active_pretty"
        echo -e "Linger: $linger_status"
        echo ""
        if [[ $service_active == "active" ]]; then
            echo "Server API: http://localhost:1234/v1/*"
            echo ""
            echo "Test API:"
            echo "  curl http://localhost:1234/v1/models"
            echo ""
            echo "Check logs:"
            echo "  systemctl --user status lmstudio-server.service"
            echo "  journalctl --user -u lmstudio-server.service"
        fi
        exit 0
    fi

    # Handle help display
    if [[ $ACTION_LOWER == "help" ]]; then
        echo "Usage: ujust toggle-lmstudio-server [enable|disable|status|help]"
        echo "If no action is provided you'll be prompted with a picker."
        echo ""
        echo "Manages LM Studio server (API-only) as a systemd user service."
        echo "More efficient than GUI mode for headless/development use."
        echo "Linger must be enabled for service to start at boot (before login)."
        exit 0
    fi

    # Interactive mode or direct action
    CHOICE=""
    if [[ -z $ACTION_LOWER ]]; then
        echo -e "${bold}LM Studio Server Service Configuration${normal}"
        echo ""
        echo -e "Service: $status_pretty, $active_pretty"
        echo -e "Linger: ${linger_status}"
        echo ""
        echo "Select action:"
        echo ""
        CHOICE=$(ugum choose \
            "Enable LM Studio Server" \
            "Disable LM Studio Server" \
            "Exit without changes")
    else
        case "$ACTION_LOWER" in
            enable) CHOICE="Enable LM Studio Server" ;;
            disable) CHOICE="Disable LM Studio Server" ;;
            *) echo "Unrecognized action: $ACTION" ; exit 1 ;;
        esac
    fi

    case "$CHOICE" in
        "Enable LM Studio Server")
            if [[ $service_enabled == "enabled" && $linger_status == "yes" ]]; then
                echo "LM Studio Server is already enabled with linger."
                exit 0
            fi

            # Create systemd user service directory if it doesn't exist
            mkdir -p "$HOME/.config/systemd/user"

            # Create service file
            cat > "$HOME/.config/systemd/user/$SERVICE" <<'EOF'
[Unit]
Description=LM Studio Server
After=network.target

[Service]
Type=simple
Environment="PATH=%h/.lmstudio/bin:%h/.local/bin:/usr/local/bin:/usr/bin"
ExecStart=%h/.lmstudio/bin/lms server start --port 1234
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=default.target
EOF

            echo "Enabling LM Studio Server service..."
            systemctl --user daemon-reload
            systemctl --user enable "$SERVICE"
            systemctl --user start "$SERVICE"

            # Enable linger for boot persistence
            if [[ $linger_status != "yes" ]]; then
                echo "Enabling linger for user $USER (required for boot persistence)..."
                loginctl enable-linger "$USER"
            fi

            echo ""
            echo -e "${green}${bold}✓ LM Studio Server enabled${normal}"
            echo ""
            echo "Service will start at boot (before login)."
            echo "Server API: http://localhost:1234/v1/*"
            echo ""
            echo "Next steps:"
            echo "  1. Load a model (GUI or API)"
            echo "  2. Test API: curl http://localhost:1234/v1/models"
            echo "  3. Check status: ujust toggle-lmstudio-server status"
            ;;

        "Disable LM Studio Server")
            if [[ $service_enabled == "disabled" ]]; then
                echo "LM Studio Server is already disabled."
                exit 0
            fi

            echo "Disabling LM Studio Server service..."
            systemctl --user stop "$SERVICE"
            systemctl --user disable "$SERVICE"

            echo ""
            echo -e "${green}${bold}✓ LM Studio Server disabled${normal}"
            echo ""
            echo "Service will no longer start at boot."

            # Warn about linger
            if [[ $linger_status == "yes" ]]; then
                echo ""
                echo -e "${yellow}Note:${normal} Linger is still enabled for user $USER."
                echo "This allows other user services to start at boot."
                echo "If you have no other services that need boot persistence,"
                echo "you can disable linger with:"
                echo "  loginctl disable-linger $USER"
            fi
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

# Install all development tools (pixi + devcontainers CLI)
[group("development")]
install-dev-tools:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Development Tools${normal}"
    echo ""

    # Install pixi
    echo "1/2 Installing pixi..."
    just install-pixi

    echo ""
    echo "2/2 Installing devcontainers CLI..."
    just install-devcontainers-cli

    echo ""
    echo -e "${green}${bold}✓ All development tools installed${normal}"

# Install linting tools (npm + cargo)
[group("development")]
install-linters:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Linting Tools${normal}"
    echo ""

    # Check prerequisites
    if ! command -v npm &> /dev/null; then
        echo -e "${red}✗ npm not found${normal}"
        echo "nodejs20 should be pre-installed on bazzite-ai"
        exit 1
    fi

    if ! command -v cargo &> /dev/null; then
        echo -e "${red}✗ cargo not found${normal}"
        echo "cargo should be pre-installed on bazzite-ai"
        exit 1
    fi

    # Configure npm if needed
    if [ "$(npm config get prefix)" = "/usr" ] || [ "$(npm config get prefix)" = "/usr/local" ]; then
        echo "Configuring npm to use user directory..."
        npm config set prefix "$HOME/.npm-global"

        if ! grep -q ".npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
        fi
    fi

    # Install markdownlint-cli
    echo "1/2 Installing markdownlint-cli (npm)..."
    if npm list -g markdownlint-cli &>/dev/null; then
        echo -e "${green}✓ markdownlint-cli already installed${normal}"
    else
        npm install -g markdownlint-cli
        echo -e "${green}✓ markdownlint-cli installed${normal}"
    fi

    echo ""

    # Install taplo-cli
    echo "2/2 Installing taplo-cli (cargo)..."
    if command -v taplo &> /dev/null; then
        echo -e "${green}✓ taplo already installed${normal}"
    else
        echo "This may take 2-3 minutes to compile..."
        cargo install taplo-cli --locked
        echo -e "${green}✓ taplo installed${normal}"
    fi

    echo ""
    echo -e "${green}${bold}✓ All linting tools installed${normal}"
    echo ""
    echo -e "${bold}Installed tools:${normal}"
    echo "  markdownlint → $HOME/.npm-global/bin/markdownlint"
    echo "  taplo        → $HOME/.cargo/bin/taplo"
    echo ""
    echo -e "${yellow}Note:${normal} Restart your shell or run: source ~/.bashrc"

# Install pre-commit hooks (requires pixi environment)
[group("development")]
lint-install:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Setting Up Pre-commit Hooks${normal}"
    echo ""

    # Check if pixi is available
    if ! command -v pixi &> /dev/null; then
        echo -e "${red}✗ pixi not found${normal}"
        echo ""
        echo "Install with: ujust install-pixi"
        exit 1
    fi

    # Check if linters installed
    export PATH="$HOME/.npm-global/bin:$HOME/.cargo/bin:$PATH"

    missing=()
    command -v markdownlint &>/dev/null || missing+=("markdownlint-cli")
    command -v taplo &>/dev/null || missing+=("taplo")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${yellow}⚠ Missing linters:${normal} ${missing[*]}"
        echo ""
        echo "Install with: ujust install-linters"
        echo ""
        read -p "Install now? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            just install-linters
        else
            exit 1
        fi
    fi

    # Install pixi environment and pre-commit hooks
    echo "Installing pixi development environment..."
    pixi install

    echo ""
    echo "Installing git hooks..."
    pixi run lint-install

    echo ""
    echo -e "${green}${bold}✓ Pre-commit hooks installed${normal}"
    echo ""
    echo -e "${bold}Usage:${normal}"
    echo "  ujust lint           # Run all linters"
    echo "  ujust lint-staged    # Run on staged files only"
    echo "  ujust lint-fix       # Auto-fix issues"
    echo "  git commit           # Automatically runs linters"

# Run all linters on all files
[group("development")]
lint:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    if ! command -v pixi &> /dev/null; then
        echo -e "${red}✗ pixi not found. Run: ujust install-pixi${normal}"
        exit 1
    fi

    echo -e "${bold}Running All Linters${normal}"
    echo ""
    pixi run lint

# Run linters on staged files only
[group("development")]
lint-staged:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    if ! command -v pixi &> /dev/null; then
        echo -e "${red}✗ pixi not found. Run: ujust install-pixi${normal}"
        exit 1
    fi

    pixi run lint-staged

# Auto-fix all linting issues
[group("development")]
lint-fix:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    if ! command -v pixi &> /dev/null; then
        echo -e "${red}✗ pixi not found. Run: ujust install-pixi${normal}"
        exit 1
    fi

    echo -e "${bold}Auto-fixing Linting Issues${normal}"
    echo ""
    pixi run lint-fix

# Update pre-commit hooks to latest versions
[group("development")]
lint-update:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    if ! command -v pixi &> /dev/null; then
        echo -e "${red}✗ pixi not found. Run: ujust install-pixi${normal}"
        exit 1
    fi

    echo -e "${bold}Updating Pre-commit Hooks${normal}"
    echo ""
    pixi run lint-update

# Install all development tools + linters
[group("development")]
install-dev-environment:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Complete Development Environment${normal}"
    echo ""

    # Install pixi
    echo "1/4 Installing pixi..."
    just install-pixi || true

    echo ""

    # Install devcontainers CLI
    echo "2/4 Installing devcontainers CLI..."
    just install-devcontainers-cli || true

    echo ""

    # Install linters
    echo "3/4 Installing linters..."
    just install-linters || true

    echo ""

    # Setup pre-commit hooks
    echo "4/4 Setting up pre-commit hooks..."
    just lint-install || true

    echo ""
    echo -e "${green}${bold}✓ Complete development environment installed${normal}"
    echo ""
    echo -e "${bold}Installed:${normal}"
    echo "  • pixi (package manager)"
    echo "  • devcontainers CLI"
    echo "  • Linting tools (markdownlint, taplo, shellcheck, yamllint)"
    echo "  • Pre-commit hooks"
    echo ""
    echo -e "${yellow}Note:${normal} Restart your shell or run: source ~/.bashrc"
