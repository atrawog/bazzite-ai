#!/usr/bin/bash
# test-devcontainers-cli.sh - Comprehensive devcontainers-cli testing
#
# Tests the devcontainers CLI installation and functionality including:
# - Installation verification
# - Core CLI commands
# - Building devcontainer configs
# - Running and executing commands in devcontainers
#
# Usage:
#   ./testing/test-devcontainers-cli.sh

set -euo pipefail

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$REPO_ROOT/testing/devcontainers-cli-test.log"
RESULTS_FILE="$REPO_ROOT/testing/devcontainers-cli-results.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Initialize results
cat > "$RESULTS_FILE" << 'EOF'
{
  "test_start": "",
  "test_end": "",
  "total_duration_seconds": 0,
  "tests_total": 0,
  "tests_passed": 0,
  "tests_failed": 0,
  "tests": {}
}
EOF

log() {
    echo -e "$@" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}  $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

test_result() {
    local test_name=$1
    local status=$2
    local message=$3

    ((TESTS_TOTAL++))

    if [ "$status" = "PASS" ]; then
        ((TESTS_PASSED++))
        log "${GREEN}✓ PASS${NC}: $test_name"
    else
        ((TESTS_FAILED++))
        log "${RED}✗ FAIL${NC}: $test_name - $message"
    fi

    # Update JSON
    local tmp=$(mktemp)
    jq ".tests.\"$test_name\" = {\"status\": \"$status\", \"message\": \"$message\"}" "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"
}

# Clear previous log
> "$LOG_FILE"

log_section "devcontainers-cli Testing - Starting"

TEST_START=$(date -Iseconds)
TEST_START_EPOCH=$(date +%s)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Phase 1: Installation Verification
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_section "Phase 1: Installation Verification"

# Test 1.1: Check if devcontainer command exists
log "Test 1.1: Checking if devcontainer command exists..."
if command -v devcontainer &> /dev/null; then
    VERSION=$(devcontainer --version)
    test_result "devcontainer-command-exists" "PASS" "Found devcontainer v$VERSION"
    log "  Version: $VERSION"
else
    test_result "devcontainer-command-exists" "FAIL" "devcontainer command not found in PATH"
    log "${RED}  devcontainer not found. Install with: ujust install-devcontainers-cli${NC}"
    exit 1
fi

# Test 1.2: Verify npm global installation
log ""
log "Test 1.2: Verifying npm global installation..."
if npm list -g @devcontainers/cli &> /dev/null; then
    NPM_VERSION=$(npm list -g @devcontainers/cli 2>/dev/null | grep @devcontainers/cli | awk '{print $2}' | sed 's/@//')
    test_result "npm-global-installation" "PASS" "@devcontainers/cli@$NPM_VERSION installed globally"
    log "  npm package: @devcontainers/cli@$NPM_VERSION"
else
    test_result "npm-global-installation" "FAIL" "Not found in npm global packages"
fi

# Test 1.3: Check PATH configuration
log ""
log "Test 1.3: Checking PATH configuration..."
DEVCONTAINER_PATH=$(which devcontainer)
if [[ "$DEVCONTAINER_PATH" == *".npm-global"* ]]; then
    test_result "path-configuration" "PASS" "devcontainer in user npm-global: $DEVCONTAINER_PATH"
    log "  Path: $DEVCONTAINER_PATH"
elif [[ "$DEVCONTAINER_PATH" == *"/usr/"* ]]; then
    test_result "path-configuration" "PASS" "devcontainer in system path: $DEVCONTAINER_PATH"
    log "  Path: $DEVCONTAINER_PATH"
else
    test_result "path-configuration" "FAIL" "Unexpected path: $DEVCONTAINER_PATH"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Phase 2: CLI Functionality
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_section "Phase 2: CLI Functionality"

# Test 2.1: Test help command
log "Test 2.1: Testing help command..."
if devcontainer --help &> /tmp/devcontainer-help.txt; then
    if grep -q "Usage:" /tmp/devcontainer-help.txt; then
        test_result "help-command" "PASS" "Help command works"
        log "  Help output generated successfully"
    else
        test_result "help-command" "FAIL" "Help output doesn't contain expected content"
    fi
else
    test_result "help-command" "FAIL" "devcontainer --help failed"
fi

# Test 2.2: Test build command availability
log ""
log "Test 2.2: Testing build subcommand..."
if devcontainer build --help &> /tmp/devcontainer-build-help.txt; then
    test_result "build-command-available" "PASS" "build subcommand available"
else
    test_result "build-command-available" "FAIL" "build subcommand not available"
fi

# Test 2.3: Test up command availability
log ""
log "Test 2.3: Testing up subcommand..."
if devcontainer up --help &> /tmp/devcontainer-up-help.txt; then
    test_result "up-command-available" "PASS" "up subcommand available"
else
    test_result "up-command-available" "FAIL" "up subcommand not available"
fi

# Test 2.4: Test exec command availability
log ""
log "Test 2.4: Testing exec subcommand..."
if devcontainer exec --help &> /tmp/devcontainer-exec-help.txt; then
    test_result "exec-command-available" "PASS" "exec subcommand available"
else
    test_result "exec-command-available" "FAIL" "exec subcommand not available"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Phase 3: Devcontainer Configuration Testing
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_section "Phase 3: Devcontainer Configuration Testing"

# Test 3.1: Verify devcontainer configs exist
log "Test 3.1: Verifying devcontainer configuration files..."
BASE_CONFIG="$REPO_ROOT/.devcontainer/devcontainer-base.json"
NVIDIA_CONFIG="$REPO_ROOT/.devcontainer/devcontainer.json"

if [[ -f "$BASE_CONFIG" ]] && [[ -f "$NVIDIA_CONFIG" ]]; then
    test_result "devcontainer-configs-exist" "PASS" "Both config files found"
    log "  Base config: $BASE_CONFIG"
    log "  NVIDIA config: $NVIDIA_CONFIG"
else
    test_result "devcontainer-configs-exist" "FAIL" "Config files missing"
    log "${RED}  Missing configuration files${NC}"
fi

# Test 3.2: Validate JSON syntax
log ""
log "Test 3.2: Validating JSON syntax..."
if jq empty "$BASE_CONFIG" 2>/dev/null; then
    test_result "base-config-valid-json" "PASS" "Base config is valid JSON"
else
    test_result "base-config-valid-json" "FAIL" "Base config has JSON syntax errors"
fi

if jq empty "$NVIDIA_CONFIG" 2>/dev/null; then
    test_result "nvidia-config-valid-json" "PASS" "NVIDIA config is valid JSON"
else
    test_result "nvidia-config-valid-json" "FAIL" "NVIDIA config has JSON syntax errors"
fi

# Test 3.3: Check config contents
log ""
log "Test 3.3: Checking configuration contents..."

BASE_IMAGE=$(jq -r '.image' "$BASE_CONFIG" 2>/dev/null || echo "null")
if [[ "$BASE_IMAGE" == *"bazzite-ai-container"* ]]; then
    test_result "base-config-image" "PASS" "Base config uses correct image: $BASE_IMAGE"
else
    test_result "base-config-image" "FAIL" "Base config image incorrect: $BASE_IMAGE"
fi

NVIDIA_IMAGE=$(jq -r '.image' "$NVIDIA_CONFIG" 2>/dev/null || echo "null")
if [[ "$NVIDIA_IMAGE" == *"bazzite-ai-container-nvidia"* ]]; then
    test_result "nvidia-config-image" "PASS" "NVIDIA config uses correct image: $NVIDIA_IMAGE"
else
    test_result "nvidia-config-image" "FAIL" "NVIDIA config image incorrect: $NVIDIA_IMAGE"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Phase 4: Build Testing (Optional - Requires Container Runtime)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_section "Phase 4: Build Testing (Optional)"

log "Checking if container runtime is available..."
if command -v podman &> /dev/null || command -v docker &> /dev/null; then
    RUNTIME_AVAILABLE=true
    log "${GREEN}✓${NC} Container runtime detected"

    # Test 4.1: Test building base config (dry-run or actual)
    log ""
    log "Test 4.1: Testing base devcontainer build..."
    log "  This may take several minutes on first run..."

    BUILD_OUTPUT="$REPO_ROOT/testing/devcontainer-base-build.log"

    if timeout 300 devcontainer build \
        --workspace-folder "$REPO_ROOT" \
        --config "$BASE_CONFIG" \
        --image-name test-bazzite-ai-devcontainer-base \
        &> "$BUILD_OUTPUT"; then
        test_result "base-devcontainer-build" "PASS" "Base devcontainer built successfully"
        log "  Build completed successfully"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            test_result "base-devcontainer-build" "FAIL" "Build timed out after 5 minutes"
        else
            test_result "base-devcontainer-build" "FAIL" "Build failed with exit code $EXIT_CODE"
            log "  Check $BUILD_OUTPUT for details"
        fi
    fi

    # Test 4.2: Test building NVIDIA config
    log ""
    log "Test 4.2: Testing NVIDIA devcontainer build..."

    BUILD_OUTPUT_NVIDIA="$REPO_ROOT/testing/devcontainer-nvidia-build.log"

    if timeout 300 devcontainer build \
        --workspace-folder "$REPO_ROOT" \
        --config "$NVIDIA_CONFIG" \
        --image-name test-bazzite-ai-devcontainer-nvidia \
        &> "$BUILD_OUTPUT_NVIDIA"; then
        test_result "nvidia-devcontainer-build" "PASS" "NVIDIA devcontainer built successfully"
        log "  Build completed successfully"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            test_result "nvidia-devcontainer-build" "FAIL" "Build timed out after 5 minutes"
        else
            test_result "nvidia-devcontainer-build" "FAIL" "Build failed with exit code $EXIT_CODE"
            log "  Check $BUILD_OUTPUT_NVIDIA for details"
        fi
    fi
else
    RUNTIME_AVAILABLE=false
    log "${YELLOW}⚠${NC} No container runtime available - skipping build tests"
    test_result "container-runtime-available" "FAIL" "No podman or docker found"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TEST_END=$(date -Iseconds)
TEST_END_EPOCH=$(date +%s)
TOTAL_DURATION=$((TEST_END_EPOCH - TEST_START_EPOCH))

# Update JSON with final results
TMP=$(mktemp)
jq ".test_start = \"$TEST_START\" |
    .test_end = \"$TEST_END\" |
    .total_duration_seconds = $TOTAL_DURATION |
    .tests_total = $TESTS_TOTAL |
    .tests_passed = $TESTS_PASSED |
    .tests_failed = $TESTS_FAILED" "$RESULTS_FILE" > "$TMP" && mv "$TMP" "$RESULTS_FILE"

log_section "Test Summary"

log "Test Results:"
log "  Total tests: $TESTS_TOTAL"
log "  ${GREEN}Passed: $TESTS_PASSED${NC}"
log "  ${RED}Failed: $TESTS_FAILED${NC}"
log "  Duration: ${TOTAL_DURATION}s"
log ""
log "Results saved to:"
log "  JSON: $RESULTS_FILE"
log "  Log: $LOG_FILE"
log ""

if [ $TESTS_FAILED -eq 0 ]; then
    log "${GREEN}${BOLD}✓ All tests passed!${NC}"
    exit 0
else
    log "${RED}${BOLD}✗ Some tests failed${NC}"
    exit 1
fi
