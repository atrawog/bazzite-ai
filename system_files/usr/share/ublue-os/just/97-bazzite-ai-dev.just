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
