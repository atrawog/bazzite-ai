#!/usr/bin/bash
set -euo pipefail

log() {
  echo "=== $* ==="
}

log "Copying system files to root filesystem"
cp -avf /tmp/system_files/. /
log "System files copied successfully"
