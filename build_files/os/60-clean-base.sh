#!/usr/bin/env bash
set -xeuo pipefail

# Add bazzite-ai just files (split into categories after refactor)
# Import all 4 category-based just files created in PR #68
cat >> /usr/share/ublue-os/justfile <<'EOF'
import "/usr/share/ublue-os/just/95-bazzite-ai-system.just"
import "/usr/share/ublue-os/just/96-bazzite-ai-apps.just"
import "/usr/share/ublue-os/just/97-bazzite-ai-dev.just"
import "/usr/share/ublue-os/just/98-bazzite-ai-virt.just"
EOF
