#!/usr/bin/bash
# Test script for devcontainers-cli fix
# Run this after rebuilding and deploying the bazzite-ai image

set -euo pipefail

echo "============================================"
echo "devcontainers-cli Fix Verification Script"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAIL++))
    fi
}

echo "Test 1: Clean state - Remove existing installation"
echo "-------------------------------------------"
if [ -d "$HOME/.npm-global" ]; then
    echo "Removing ~/.npm-global for clean test..."
    rm -rf ~/.npm-global
fi
if grep -q ".npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo "Removing PATH entry from .bashrc..."
    sed -i '/\.npm-global\/bin/d' ~/.bashrc
fi
npm config delete prefix 2>/dev/null || true
echo "✓ Clean state achieved"
echo ""

echo "Test 2: Fresh installation"
echo "-------------------------------------------"
OUTPUT=$(ujust install-devcontainers-cli 2>&1)
if echo "$OUTPUT" | grep -q "✓ Success" && ! echo "$OUTPUT" | grep -q "✗ Error"; then
    test_result 0 "Fresh install shows success (no false error)"
else
    test_result 1 "Fresh install failed or showed false error"
    echo "Output:"
    echo "$OUTPUT"
fi
echo ""

echo "Test 3: Binary exists and is executable"
echo "-------------------------------------------"
if [ -x "$HOME/.npm-global/bin/devcontainer" ]; then
    test_result 0 "Binary exists at ~/.npm-global/bin/devcontainer"
else
    test_result 1 "Binary not found or not executable"
fi
echo ""

echo "Test 4: Binary works"
echo "-------------------------------------------"
if "$HOME/.npm-global/bin/devcontainer" --version &> /dev/null; then
    VERSION=$("$HOME/.npm-global/bin/devcontainer" --version)
    test_result 0 "Binary functional (version: $VERSION)"
else
    test_result 1 "Binary exists but doesn't run"
fi
echo ""

echo "Test 5: PATH updated in .bashrc"
echo "-------------------------------------------"
if grep -q ".npm-global/bin" "$HOME/.bashrc"; then
    test_result 0 "PATH entry added to .bashrc"
else
    test_result 1 "PATH entry missing from .bashrc"
fi
echo ""

echo "Test 6: Available in new shell"
echo "-------------------------------------------"
if bash -l -c 'command -v devcontainer &> /dev/null'; then
    test_result 0 "devcontainer available in new shell"
else
    test_result 1 "devcontainer not available in new shell"
fi
echo ""

echo "Test 7: Idempotency - Re-run installation"
echo "-------------------------------------------"
OUTPUT=$(ujust install-devcontainers-cli 2>&1)
if echo "$OUTPUT" | grep -q "already installed" && ! echo "$OUTPUT" | grep -q "Installing @devcontainers/cli"; then
    test_result 0 "Idempotency check detected existing installation"
else
    test_result 1 "Idempotency check failed (reinstalled or showed error)"
    echo "Output:"
    echo "$OUTPUT"
fi
echo ""

echo "Test 8: Version check works in idempotency path"
echo "-------------------------------------------"
OUTPUT=$(ujust install-devcontainers-cli 2>&1)
if echo "$OUTPUT" | grep -E "[0-9]+\.[0-9]+\.[0-9]+"; then
    VERSION=$(echo "$OUTPUT" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
    test_result 0 "Version displayed: $VERSION"
else
    test_result 1 "Version not displayed in output"
fi
echo ""

echo "Test 9: Integration - install-dev-tools"
echo "-------------------------------------------"
# Remove devcontainer for clean test
rm -rf ~/.npm-global/lib/node_modules/@devcontainers
OUTPUT=$(ujust install-dev-tools 2>&1)
if echo "$OUTPUT" | grep -q "✓ Success" && echo "$OUTPUT" | grep -q "devcontainers CLI installed"; then
    test_result 0 "install-dev-tools successfully installs devcontainers-cli"
else
    test_result 1 "install-dev-tools failed for devcontainers-cli"
fi
echo ""

echo "============================================"
echo "Test Results Summary"
echo "============================================"
echo -e "${GREEN}PASSED: $PASS${NC}"
echo -e "${RED}FAILED: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! The fix works correctly.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Review output above.${NC}"
    exit 1
fi
