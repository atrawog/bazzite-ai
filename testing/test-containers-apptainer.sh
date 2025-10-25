#!/usr/bin/bash
# test-containers-apptainer.sh - Comprehensive Apptainer container testing
#
# Tests the production container workflow using ujust commands:
# - ujust apptainer-pull-container (base)
# - ujust apptainer-pull-container-nvidia
# - ujust apptainer-run-container
# - ujust apptainer-run-container-nvidia
# - ujust apptainer-exec-container-nvidia
#
# This is the PRIMARY testing path for end-user container usage.
#
# Usage:
#   ./testing/test-containers-apptainer.sh [--skip-pull]
#
# Options:
#   --skip-pull  Skip pulling containers (use existing .sif files)

set -euo pipefail

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$REPO_ROOT/testing/apptainer-test.log"
RESULTS_FILE="$REPO_ROOT/testing/apptainer-test-results.json"

# Parse arguments
SKIP_PULL=false
if [ $# -gt 0 ] && [ "$1" = "--skip-pull" ]; then
    SKIP_PULL=true
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

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
  "skip_pull": false,
  "base_container": {
    "sif_file": "",
    "size_mb": 0,
    "pulled": false,
    "run_successful": false
  },
  "nvidia_container": {
    "sif_file": "",
    "size_mb": 0,
    "pulled": false,
    "run_successful": false
  },
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

    local tmp=$(mktemp)
    jq ".tests.\"$test_name\" = {\"status\": \"$status\", \"message\": \"$message\"}" "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"
}

update_json() {
    local field=$1
    local value=$2
    local tmp=$(mktemp)
    jq "$field = $value" "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"
}

# Clear previous log
> "$LOG_FILE"

log_section "Apptainer Container Testing (Production Workflow)"

TEST_START=$(date -Iseconds)
TEST_START_EPOCH=$(date +%s)

update_json '.test_start' "\"$TEST_START\""
update_json '.skip_pull' "$SKIP_PULL"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Phase 1: Prerequisites
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_section "Phase 1: Prerequisites"

# Test 1.1: Check Apptainer installation
log "Test 1.1: Checking Apptainer installation..."
if command -v apptainer &> /dev/null; then
    APPTAINER_VERSION=$(apptainer version)
    test_result "apptainer-installed" "PASS" "Apptainer $APPTAINER_VERSION installed"
    log "  Version: $APPTAINER_VERSION"
else
    test_result "apptainer-installed" "FAIL" "Apptainer not found"
    log "${RED}Apptainer is required but not installed${NC}"
    exit 1
fi

# Test 1.2: Check ujust command availability
log ""
log "Test 1.2: Checking ujust availability..."
if command -v ujust &> /dev/null; then
    test_result "ujust-available" "PASS" "ujust command found"
else
    test_result "ujust-available" "FAIL" "ujust command not found"
    log "${YELLOW}Note: Using 'just' as fallback${NC}"
fi

# Test 1.3: Verify ujust apptainer commands exist
log ""
log "Test 1.3: Verifying ujust apptainer commands..."
UJUST_COMMANDS=(
    "apptainer-info"
    "apptainer-pull-container"
    "apptainer-pull-container-nvidia"
    "apptainer-run-container"
    "apptainer-run-container-nvidia"
    "apptainer-exec-container-nvidia"
)

COMMANDS_FOUND=0
for cmd in "${UJUST_COMMANDS[@]}"; do
    if ujust --list 2>&1 | grep -q "$cmd"; then
        ((COMMANDS_FOUND++))
    fi
done

if [ $COMMANDS_FOUND -eq ${#UJUST_COMMANDS[@]} ]; then
    test_result "ujust-commands-available" "PASS" "All ${#UJUST_COMMANDS[@]} apptainer commands found"
else
    test_result "ujust-commands-available" "FAIL" "Only $COMMANDS_FOUND/${#UJUST_COMMANDS[@]} commands found"
fi

# Test 1.4: Display Apptainer info
log ""
log "Test 1.4: Getting Apptainer system information..."
if ujust apptainer-info &> "$REPO_ROOT/testing/apptainer-info.log"; then
    test_result "apptainer-info-command" "PASS" "apptainer-info executed successfully"
    log "  Output saved to testing/apptainer-info.log"
else
    test_result "apptainer-info-command" "FAIL" "apptainer-info command failed"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Phase 2: Base Container (bazzite-ai-container)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_section "Phase 2: Base Container (CPU-only)"

BASE_SIF="$HOME/bazzite-ai-container_latest.sif"
update_json '.base_container.sif_file' "\"$BASE_SIF\""

# Test 2.1: Pull base container
if [ "$SKIP_PULL" = false ]; then
    log "Test 2.1: Pulling base container with ujust..."
    log "  Command: ujust apptainer-pull-container"
    log "  This may take several minutes..."
    log ""

    PULL_START=$(date +%s)
    if timeout 600 ujust apptainer-pull-container &> "$REPO_ROOT/testing/apptainer-pull-base.log"; then
        PULL_END=$(date +%s)
        PULL_DURATION=$((PULL_END - PULL_START))
        test_result "pull-base-container" "PASS" "Pulled successfully in ${PULL_DURATION}s"
        update_json '.base_container.pulled' "true"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            test_result "pull-base-container" "FAIL" "Timed out after 10 minutes"
        else
            test_result "pull-base-container" "FAIL" "Pull failed with exit code $EXIT_CODE"
        fi
    fi
else
    log "Test 2.1: Skipping pull (--skip-pull mode)"
    test_result "pull-base-container" "SKIP" "Using existing .sif file"
fi

# Test 2.2: Verify .sif file exists
log ""
log "Test 2.2: Verifying .sif file..."
if [[ -f "$BASE_SIF" ]]; then
    FILE_SIZE_MB=$(du -m "$BASE_SIF" | cut -f1)
    update_json '.base_container.size_mb' "$FILE_SIZE_MB"
    test_result "base-sif-exists" "PASS" "File exists: ${FILE_SIZE_MB} MB"
    log "  Location: $BASE_SIF"
    log "  Size: ${FILE_SIZE_MB} MB"
else
    test_result "base-sif-exists" "FAIL" "File not found: $BASE_SIF"
fi

# Test 2.3: Test running base container with commands
log ""
log "Test 2.3: Testing command execution in base container..."

TEST_SCRIPT="/tmp/apptainer-base-test.sh"
cat > "$TEST_SCRIPT" << 'TESTSCRIPT'
#!/bin/bash
echo "=== Base Container Environment Test ==="
echo "User: $(whoami)"
echo "Home: $HOME"
echo "Shell: $SHELL"
echo "PWD: $(pwd)"
echo ""
echo "=== Tool Versions ==="
python3 --version 2>&1 || echo "Python: not found"
node --version 2>&1 || echo "Node: not found"
npm --version 2>&1 || echo "npm: not found"
git --version 2>&1 || echo "Git: not found"
echo ""
echo "=== Test Complete ==="
TESTSCRIPT
chmod +x "$TEST_SCRIPT"

if [[ -f "$BASE_SIF" ]]; then
    log "  Executing test script in container..."
    if apptainer exec --writable-tmpfs "$BASE_SIF" bash "$TEST_SCRIPT" &> "$REPO_ROOT/testing/apptainer-base-exec.log"; then
        test_result "base-container-exec" "PASS" "Commands executed successfully"
        log "  Output saved to testing/apptainer-base-exec.log"

        # Check for specific tools
        if grep -q "Python 3" "$REPO_ROOT/testing/apptainer-base-exec.log"; then
            test_result "base-container-python" "PASS" "Python found in container"
        else
            test_result "base-container-python" "FAIL" "Python not found in container"
        fi

        if grep -q "v2" "$REPO_ROOT/testing/apptainer-base-exec.log" | grep -i node; then
            test_result "base-container-node" "PASS" "Node.js found in container"
        else
            test_result "base-container-node" "FAIL" "Node.js not found in container"
        fi
    else
        test_result "base-container-exec" "FAIL" "Command execution failed"
    fi
else
    log "${YELLOW}  Skipping - .sif file not available${NC}"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Phase 3: NVIDIA Container (bazzite-ai-container-nvidia)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_section "Phase 3: NVIDIA Container (GPU-enabled)"

NVIDIA_SIF="$HOME/bazzite-ai-container-nvidia_latest.sif"
update_json '.nvidia_container.sif_file' "\"$NVIDIA_SIF\""

# Test 3.1: Pull NVIDIA container
if [ "$SKIP_PULL" = false ]; then
    log "Test 3.1: Pulling NVIDIA container with ujust..."
    log "  Command: ujust apptainer-pull-container-nvidia"
    log "  This may take several minutes..."
    log ""

    PULL_START=$(date +%s)
    if timeout 600 ujust apptainer-pull-container-nvidia &> "$REPO_ROOT/testing/apptainer-pull-nvidia.log"; then
        PULL_END=$(date +%s)
        PULL_DURATION=$((PULL_END - PULL_START))
        test_result "pull-nvidia-container" "PASS" "Pulled successfully in ${PULL_DURATION}s"
        update_json '.nvidia_container.pulled' "true"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            test_result "pull-nvidia-container" "FAIL" "Timed out after 10 minutes"
        else
            test_result "pull-nvidia-container" "FAIL" "Pull failed with exit code $EXIT_CODE"
        fi
    fi
else
    log "Test 3.1: Skipping pull (--skip-pull mode)"
    test_result "pull-nvidia-container" "SKIP" "Using existing .sif file"
fi

# Test 3.2: Verify NVIDIA .sif file
log ""
log "Test 3.2: Verifying NVIDIA .sif file..."
if [[ -f "$NVIDIA_SIF" ]]; then
    FILE_SIZE_MB=$(du -m "$NVIDIA_SIF" | cut -f1)
    update_json '.nvidia_container.size_mb' "$FILE_SIZE_MB"
    test_result "nvidia-sif-exists" "PASS" "File exists: ${FILE_SIZE_MB} MB"
    log "  Location: $NVIDIA_SIF"
    log "  Size: ${FILE_SIZE_MB} MB"

    # Compare sizes
    if [[ -f "$BASE_SIF" ]]; then
        BASE_SIZE=$(du -m "$BASE_SIF" | cut -f1)
        SIZE_DIFF=$((FILE_SIZE_MB - BASE_SIZE))
        log "  Size difference from base: +${SIZE_DIFF} MB"
    fi
else
    test_result "nvidia-sif-exists" "FAIL" "File not found: $NVIDIA_SIF"
fi

# Test 3.3: Test NVIDIA container execution
log ""
log "Test 3.3: Testing NVIDIA container execution..."

if [[ -f "$NVIDIA_SIF" ]]; then
    log "  Using ujust apptainer-exec-container-nvidia..."

    # Test simple command
    if ujust apptainer-exec-container-nvidia "echo 'Test successful'" &> /tmp/nvidia-exec-test.log; then
        test_result "nvidia-container-exec-simple" "PASS" "Simple command execution works"
    else
        test_result "nvidia-container-exec-simple" "FAIL" "Simple command failed"
    fi

    # Test Python availability
    if ujust apptainer-exec-container-nvidia "python3 --version" &> /tmp/nvidia-python-test.log; then
        PYTHON_VERSION=$(cat /tmp/nvidia-python-test.log)
        test_result "nvidia-container-python" "PASS" "Python found: $PYTHON_VERSION"
    else
        test_result "nvidia-container-python" "FAIL" "Python not found"
    fi

    # Test CUDA libraries (won't execute but files should exist)
    log "  Checking for CUDA/ML libraries..."
    if ujust apptainer-exec-container-nvidia "find /usr -name 'libcudnn*' 2>/dev/null | head -3" &> /tmp/nvidia-cudnn-check.log; then
        if grep -q "libcudnn" /tmp/nvidia-cudnn-check.log; then
            test_result "nvidia-container-cudnn" "PASS" "cuDNN libraries found"
        else
            test_result "nvidia-container-cudnn" "FAIL" "cuDNN libraries not found"
        fi
    fi
else
    log "${YELLOW}  Skipping - .sif file not available${NC}"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TEST_END=$(date -Iseconds)
TEST_END_EPOCH=$(date +%s)
TOTAL_DURATION=$((TEST_END_EPOCH - TEST_START_EPOCH))

update_json '.test_end' "\"$TEST_END\""
update_json '.total_duration_seconds' "$TOTAL_DURATION"
update_json '.tests_total' "$TESTS_TOTAL"
update_json '.tests_passed' "$TESTS_PASSED"
update_json '.tests_failed' "$TESTS_FAILED"

log_section "Test Summary"

log "Container Files:"
if [[ -f "$BASE_SIF" ]]; then
    BASE_SIZE=$(du -m "$BASE_SIF" | cut -f1)
    log "  Base: $BASE_SIF (${BASE_SIZE} MB)"
fi
if [[ -f "$NVIDIA_SIF" ]]; then
    NVIDIA_SIZE=$(du -m "$NVIDIA_SIF" | cut -f1)
    log "  NVIDIA: $NVIDIA_SIF (${NVIDIA_SIZE} MB)"
fi

log ""
log "Test Results:"
log "  Total tests: $TESTS_TOTAL"
log "  ${GREEN}Passed: $TESTS_PASSED${NC}"
log "  ${RED}Failed: $TESTS_FAILED${NC}"
log "  Duration: ${TOTAL_DURATION}s ($((TOTAL_DURATION / 60)) minutes)"
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
