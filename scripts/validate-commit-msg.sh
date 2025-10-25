#!/usr/bin/env bash
set -e

# Get commit message from file passed by git
COMMIT_MSG_FILE="${1:-/dev/stdin}"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Extract first line only (ignore body)
FIRST_LINE=$(echo "$COMMIT_MSG" | head -n1)

# Allowed prefixes (must match CI validation)
ALLOWED_PREFIXES=("Fix:" "Feat:" "Docs:" "Chore:" "Refactor:" "Style:")

# Skip merge commits and revert commits
if [[ "$FIRST_LINE" =~ ^Merge || "$FIRST_LINE" =~ ^Revert ]]; then
  exit 0
fi

# Check if message starts with allowed prefix
valid=false
for prefix in "${ALLOWED_PREFIXES[@]}"; do
  if [[ "$FIRST_LINE" =~ ^"$prefix " ]]; then
    valid=true
    break
  fi
done

if [[ "$valid" == false ]]; then
  cat << 'EOF'
❌ ERROR: Commit message doesn't follow semantic convention

Your commit message:
EOF
  echo "  $FIRST_LINE"
  cat << 'EOF'

Required format: <Type>: <description>

Allowed types:
  Fix:      Bug fixes
  Feat:     New features
  Docs:     Documentation changes
  Chore:    Maintenance, dependencies, config
  Refactor: Code refactoring
  Style:    Code formatting, style changes

Examples:
  ✓ Fix: correct path handling in build script
  ✓ Feat: add GPU support for containers
  ✓ Docs: update installation guide

To bypass (NOT RECOMMENDED): git commit --no-verify
EOF
  exit 1
fi

exit 0
