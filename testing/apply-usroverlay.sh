#!/usr/bin/bash
# apply-usroverlay.sh - Apply rpm-ostree usroverlay and copy test files
#
# This script enables full environment testing by making /usr temporarily writable
# and copying modified justfiles from the repository to the system.
#
# ⚠️  WARNING: Requires reboot to fully undo changes!
#
# Usage:
#   sudo ./testing/apply-usroverlay.sh [--transient|--hotfix]
#
# Options:
#   --transient  Temporary overlay (lost on reboot) [DEFAULT]
#   --hotfix     Persistent overlay (survives reboot)
#
# Example:
#   sudo ./testing/apply-usroverlay.sh --transient

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/system_files/usr/share/ublue-os/just"
TARGET_DIR="/usr/share/ublue-os/just"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} This script must be run as root (use sudo)"
    exit 1
fi

# Parse arguments
MODE="--transient"
if [ $# -gt 0 ]; then
    case "$1" in
        --transient|--hotfix)
            MODE="$1"
            ;;
        *)
            echo -e "${RED}Error:${NC} Invalid option: $1"
            echo "Usage: sudo $0 [--transient|--hotfix]"
            exit 1
            ;;
    esac
fi

# Display warning
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  rpm-ostree usroverlay - System Modification${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${RED}⚠️  WARNING: This will modify your immutable system!${NC}"
echo ""
echo "Mode: ${BLUE}$MODE${NC}"
if [ "$MODE" = "--transient" ]; then
    echo "  - Changes will be LOST on reboot"
    echo "  - Requires reboot to fully undo"
else
    echo "  - Changes will PERSIST across reboots"
    echo "  - Requires manual cleanup or rebase to undo"
fi
echo ""
echo "Files to be copied:"
echo "  From: $SOURCE_DIR"
echo "  To:   $TARGET_DIR"
echo ""

# List files that will be modified
echo "Files that will be modified:"
for file in "$SOURCE_DIR"/9*.just; do
    filename=$(basename "$file")
    if [ -f "$TARGET_DIR/$filename" ]; then
        echo "  - $filename (will be overwritten)"
    else
        echo "  - $filename (new file)"
    fi
done
echo ""

read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Step 1: Apply usroverlay
echo ""
echo -e "${BLUE}Step 1:${NC} Applying rpm-ostree usroverlay $MODE..."
if rpm-ostree usroverlay $MODE; then
    echo -e "${GREEN}✓${NC} usroverlay applied"
else
    echo -e "${RED}✗${NC} Failed to apply usroverlay"
    exit 1
fi

# Step 2: Backup original files
echo ""
echo -e "${BLUE}Step 2:${NC} Creating backup of original files..."
BACKUP_DIR="/var/tmp/bazzite-ai-just-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for file in "$SOURCE_DIR"/9*.just; do
    filename=$(basename "$file")
    if [ -f "$TARGET_DIR/$filename" ]; then
        cp "$TARGET_DIR/$filename" "$BACKUP_DIR/"
        echo "  - Backed up: $filename"
    fi
done
echo -e "${GREEN}✓${NC} Backup saved to: $BACKUP_DIR"

# Step 3: Copy modified files
echo ""
echo -e "${BLUE}Step 3:${NC} Copying modified justfiles from repository..."
for file in "$SOURCE_DIR"/9*.just; do
    filename=$(basename "$file")
    cp "$file" "$TARGET_DIR/"
    echo "  - Copied: $filename"
done
echo -e "${GREEN}✓${NC} Files copied successfully"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  usroverlay Applied Successfully${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo "You can now test ujust commands with modified recipes:"
echo "  ujust install-devcontainers-cli"
echo "  ujust install-dev-tools"
echo "  etc."
echo ""
echo -e "${YELLOW}To undo changes:${NC}"
if [ "$MODE" = "--transient" ]; then
    echo "  1. Reboot the system"
    echo "     sudo systemctl reboot"
else
    echo "  1. Restore from backup:"
    echo "     sudo cp $BACKUP_DIR/* $TARGET_DIR/"
    echo "  2. Then reboot to restore immutability"
fi
echo ""
echo -e "${YELLOW}Backup location:${NC} $BACKUP_DIR"
echo ""
