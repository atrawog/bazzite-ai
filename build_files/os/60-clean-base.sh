#!/usr/bin/env bash
set -xeuo pipefail

# Add bazzite-ai just file
echo "import \"/usr/share/ublue-os/just/95-bazzite-ai.just\"" >> /usr/share/ublue-os/justfile
