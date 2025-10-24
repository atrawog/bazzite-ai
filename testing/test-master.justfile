# test-master.justfile
# Test justfile for local ujust recipe development
#
# This justfile imports bazzite-ai recipes from the repository for testing
# without modifying the immutable system or rebuilding the image.
#
# Usage: ./testing/ujust-test <recipe>

set allow-duplicate-recipes := true
set ignore-comments := true

# Get repository root directory
repo_root := justfile_directory() / ".."

_default:
    #!/usr/bin/bash
    echo "Test Mode: Using justfiles from repository"
    echo "Repository: {{repo_root}}"
    echo ""
    just --justfile {{justfile()}} --list --list-heading $'Available test recipes:\n' --list-prefix $' - '

# Import bazzite-ai justfile modules from repository
# Note: Imports use relative paths from testing/ directory
# Only bazzite-ai modules are imported; system modules use installed versions
import? "../system_files/usr/share/ublue-os/just/95-bazzite-ai-system.just"
import? "../system_files/usr/share/ublue-os/just/96-bazzite-ai-apps.just"
import "../system_files/usr/share/ublue-os/just/97-bazzite-ai-dev.just"
import? "../system_files/usr/share/ublue-os/just/98-bazzite-ai-virt.just"

# Test recipe to verify imports work
[group("test")]
test-imports:
    #!/usr/bin/bash
    echo "✓ Test justfile loaded successfully"
    echo "✓ Repository: {{repo_root}}"
    echo "✓ System files: {{repo_root}}/system_files"
    echo ""
    echo "Imported bazzite-ai modules:"
    echo "  - 95-bazzite-ai-system.just"
    echo "  - 96-bazzite-ai-apps.just"
    echo "  - 97-bazzite-ai-dev.just"
    echo "  - 98-bazzite-ai-virt.just"
