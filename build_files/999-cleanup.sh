#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Starting system cleanup"

# Clean package manager cache
dnf5 clean all

# Clean temporary files
rm -rf /tmp/*

# Cleanup the entirety of `/var`.
# None of these get in the end-user system and bootc lints get super mad if anything is in there
# Note: Preserve /var/cache to avoid conflicts with DNF cache mounts in Containerfile
find /var -mindepth 1 -maxdepth 1 ! -path '/var/cache' -exec rm -rf {} +
mkdir -p /var

# Commit and lint container
# Known lint warning: sysusers - Some /etc/group entries may lack systemd sysusers.d config
# This is a lint warning that doesn't affect image functionality
bootc container lint || true

log "Cleanup completed"
