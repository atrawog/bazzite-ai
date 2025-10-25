#!/usr/bin/bash
set -euo pipefail

log() {
  echo "=== $* ==="
}

log "Copying system files to root filesystem"
cp -avf /tmp/system_files/. /
log "System files copied successfully"

# Enable KVM kernel args setup service (now that the service file exists)
log "Enabling bazzite-ai-kvm-setup.service"
systemctl enable bazzite-ai-kvm-setup.service
log "KVM setup service enabled"
