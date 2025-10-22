#!/usr/bin/env bash
# Bazzite AI Torrent Seeding Service Setup
# Sets up transmission-daemon as systemd user service for ISO seeding

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory (repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="bazzite-ai-seeding"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
CONFIG_DIR="${HOME}/.config/transmission-daemon"
INCOMPLETE_DIR="${REPO_DIR}/.incomplete-torrents"

log_info "Bazzite AI Torrent Seeding Service Setup"
echo "=========================================="
echo

# Check if transmission is installed
log_info "Checking for transmission-daemon..."
if ! command -v transmission-daemon &> /dev/null; then
    log_error "transmission-daemon not found"
    echo
    echo "Install with:"
    echo "  sudo dnf install transmission transmission-daemon transmission-cli"
    echo
    exit 1
fi

TRANSMISSION_VERSION=$(transmission-daemon --version | head -n1)
log_success "Found: ${TRANSMISSION_VERSION}"
echo

# Create directories
log_info "Creating directories..."
mkdir -p "${SYSTEMD_USER_DIR}"
mkdir -p "${CONFIG_DIR}"
mkdir -p "${INCOMPLETE_DIR}"
log_success "Directories created"
echo

# Generate transmission-daemon configuration
log_info "Generating transmission-daemon configuration..."
cat > "${REPO_DIR}/.transmission-daemon.json" <<EOF
{
    "alt-speed-down": 5000,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 500,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "cache-size-mb": 16,
    "dht-enabled": true,
    "download-dir": "${REPO_DIR}",
    "download-queue-enabled": true,
    "download-queue-size": 5,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "${INCOMPLETE_DIR}",
    "incomplete-dir-enabled": true,
    "lpd-enabled": false,
    "message-level": 1,
    "peer-congestion-algorithm": "",
    "peer-limit-global": 200,
    "peer-limit-per-torrent": 50,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": true,
    "preallocation": 1,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2.0,
    "ratio-limit-enabled": true,
    "rename-partial-files": true,
    "rpc-authentication-required": false,
    "rpc-bind-address": "127.0.0.1",
    "rpc-enabled": true,
    "rpc-host-whitelist": "127.0.0.1",
    "rpc-host-whitelist-enabled": true,
    "rpc-port": 9091,
    "rpc-url": "/transmission/",
    "rpc-whitelist": "127.0.0.1",
    "rpc-whitelist-enabled": true,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "seed-queue-enabled": false,
    "seed-queue-size": 10,
    "speed-limit-down": 10000,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 5000,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": false,
    "umask": 18,
    "upload-slots-per-torrent": 14,
    "utp-enabled": true
}
EOF

log_success "Configuration written to ${REPO_DIR}/.transmission-daemon.json"
echo

# Create systemd service file
log_info "Creating systemd user service..."
cat > "${SYSTEMD_USER_DIR}/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Bazzite AI ISO Torrent Seeding Service
Documentation=https://github.com/atrawog/bazzite-ai
After=network.target

[Service]
Type=simple
WorkingDirectory=${REPO_DIR}
ExecStart=/usr/bin/transmission-daemon \\
  --foreground \\
  --config-dir ${REPO_DIR} \\
  --log-level=info
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
RestartSec=5

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=${REPO_DIR}

[Install]
WantedBy=default.target
EOF

log_success "Service file created: ${SYSTEMD_USER_DIR}/${SERVICE_NAME}.service"
echo

# Reload systemd user daemon
log_info "Reloading systemd user daemon..."
systemctl --user daemon-reload
log_success "Systemd daemon reloaded"
echo

# Enable service (but don't start yet)
log_info "Enabling service..."
systemctl --user enable "${SERVICE_NAME}.service"
log_success "Service enabled"
echo

# Display status and instructions
echo "=========================================="
log_success "Setup complete!"
echo "=========================================="
echo
echo "Service: ${SERVICE_NAME}.service"
echo "Status:  Enabled (not started)"
echo
echo "Commands:"
echo "  Start:   systemctl --user start ${SERVICE_NAME}"
echo "  Stop:    systemctl --user stop ${SERVICE_NAME}"
echo "  Status:  systemctl --user status ${SERVICE_NAME}"
echo "  Logs:    journalctl --user -u ${SERVICE_NAME} -f"
echo
echo "Or use Just commands:"
echo "  just release-seed-start <tag>   # Starts service and adds torrents"
echo "  just release-seed-stop          # Stops service"
echo "  just release-seed-status        # Shows seeding status"
echo
echo "Configuration:"
echo "  Daemon config:  ${REPO_DIR}/.transmission-daemon.json"
echo "  Download dir:   ${REPO_DIR}"
echo "  Incomplete dir: ${INCOMPLETE_DIR}"
echo "  RPC Port:       9091 (localhost only)"
echo "  Peer Port:      51413"
echo "  Ratio limit:    2.0 (stops seeding at 2:1 ratio)"
echo
log_warn "Note: The service is enabled but not started."
log_warn "Use 'just release-seed-start <tag>' to begin seeding."
echo
