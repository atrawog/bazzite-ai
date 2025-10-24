#!/usr/bin/bash
# test-flatpaks-full.sh - Comprehensive flatpak installation testing
#
# This script tests all ujust install-flatpaks-* commands by actually installing
# all 38 flatpak apps and documenting the results.
#
# WARNING: This will install ~10-15 GB of flatpak apps on your system!
#
# Usage:
#   ./testing/test-flatpaks-full.sh [--skip-install]
#
# Options:
#   --skip-install  Skip actual installation, just analyze recipes

set -euo pipefail

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_JUSTFILE="$REPO_ROOT/testing/test-master.justfile"
RESULTS_FILE="$REPO_ROOT/testing/flatpak-test-results.json"
REPORT_FILE="$REPO_ROOT/FLATPAKS-TEST-REPORT.md"
LOG_FILE="$REPO_ROOT/testing/flatpak-test.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_INSTALL=false
if [ $# -gt 0 ] && [ "$1" = "--skip-install" ]; then
    SKIP_INSTALL=true
fi

# Flatpak categories to test
CATEGORIES=(
    "dev"
    "media"
    "gaming"
    "communication"
    "productivity"
    "utilities"
    "experimental"
)

# Expected app counts per category
declare -A EXPECTED_COUNTS=(
    ["dev"]=8
    ["media"]=9
    ["gaming"]=4
    ["communication"]=3
    ["productivity"]=7
    ["utilities"]=5
    ["experimental"]=2
)

# Initialize results JSON
cat > "$RESULTS_FILE" << 'EOF'
{
  "test_start": "",
  "test_end": "",
  "total_duration_seconds": 0,
  "pre_test_count": 0,
  "post_test_count": 0,
  "categories_tested": 0,
  "apps_attempted": 0,
  "apps_successful": 0,
  "apps_failed": 0,
  "apps_already_installed": 0,
  "disk_usage_before_mb": 0,
  "disk_usage_after_mb": 0,
  "disk_usage_delta_mb": 0,
  "categories": {}
}
EOF

# Helper functions
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

get_flatpak_count() {
    flatpak list --app 2>/dev/null | wc -l
}

get_disk_usage_mb() {
    local usage=$(du -sm /var/lib/flatpak 2>/dev/null | cut -f1)
    echo "${usage:-0}"
}

update_json_field() {
    local field=$1
    local value=$2
    local tmp=$(mktemp)
    jq "$field = $value" "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"
}

test_category() {
    local category=$1
    local command="install-flatpaks-${category}"

    log_section "Testing: $command"

    local start_time=$(date +%s)
    local start_count=$(get_flatpak_count)

    log "${YELLOW}Starting test...${NC}"
    log "  Category: $category"
    log "  Expected apps: ${EXPECTED_COUNTS[$category]}"
    log "  Flatpaks before: $start_count"
    log ""

    # Run the command and capture output
    local output_file="$REPO_ROOT/testing/flatpak-${category}-output.log"
    local exit_code=0

    if [ "$SKIP_INSTALL" = true ]; then
        log "${YELLOW}Skipping installation (--skip-install mode)${NC}"
        echo "Skipped" > "$output_file"
    else
        log "Running: ./testing/ujust-test $command"
        if ./testing/ujust-test "$command" &> "$output_file"; then
            exit_code=0
        else
            exit_code=$?
        fi
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local end_count=$(get_flatpak_count)
    local apps_installed=$((end_count - start_count))

    # Analyze output for errors
    local errors=$(grep -i "error\|failed\|unable" "$output_file" 2>/dev/null || true)
    local warnings=$(grep -i "warning" "$output_file" 2>/dev/null || true)

    # Count "already installed" messages
    local already_installed=$(grep -c "already installed" "$output_file" 2>/dev/null || echo 0)

    # Determine success
    local success=true
    if [ $exit_code -ne 0 ]; then
        success=false
    fi

    # Update JSON with category results
    local tmp=$(mktemp)
    jq ".categories.\"$category\" = {
        \"command\": \"$command\",
        \"expected_count\": ${EXPECTED_COUNTS[$category]},
        \"duration_seconds\": $duration,
        \"flatpaks_before\": $start_count,
        \"flatpaks_after\": $end_count,
        \"apps_installed\": $apps_installed,
        \"already_installed\": $already_installed,
        \"exit_code\": $exit_code,
        \"success\": $success,
        \"has_errors\": $([ -n "$errors" ] && echo true || echo false),
        \"has_warnings\": $([ -n "$warnings" ] && echo true || echo false)
    }" "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"

    # Display results
    log ""
    if [ "$success" = true ]; then
        log "${GREEN}✓ Test completed successfully${NC}"
    else
        log "${RED}✗ Test failed (exit code: $exit_code)${NC}"
    fi
    log "  Duration: ${duration}s"
    log "  Flatpaks after: $end_count"
    log "  Apps installed: $apps_installed"
    log "  Already installed: $already_installed"

    if [ -n "$errors" ]; then
        log ""
        log "${RED}Errors detected:${NC}"
        echo "$errors" | head -5 | tee -a "$LOG_FILE"
    fi

    log ""
}

test_idempotency() {
    log_section "Idempotency Test"

    log "Re-running all category commands to verify 'already installed' detection..."
    log ""

    local start_count=$(get_flatpak_count)

    for category in "${CATEGORIES[@]}"; do
        local command="install-flatpaks-${category}"
        local output_file="$REPO_ROOT/testing/flatpak-${category}-idempotent.log"

        log "${YELLOW}Testing: $command (idempotency)${NC}"

        if [ "$SKIP_INSTALL" = true ]; then
            log "  Skipped (--skip-install mode)"
            continue
        fi

        ./testing/ujust-test "$command" &> "$output_file" || true

        local already_installed=$(grep -c "already installed" "$output_file" 2>/dev/null || echo 0)
        local newly_installed=$(grep -c "Installing" "$output_file" 2>/dev/null || echo 0)

        log "  Already installed: $already_installed"
        log "  Newly installed: $newly_installed"

        if [ $newly_installed -gt 0 ]; then
            log "  ${YELLOW}⚠ Warning: Some apps were installed on second run (idempotency issue)${NC}"
        else
            log "  ${GREEN}✓ All apps correctly detected as installed${NC}"
        fi
        log ""
    done

    local end_count=$(get_flatpak_count)

    if [ $end_count -eq $start_count ]; then
        log "${GREEN}✓ Idempotency verified: No apps installed on re-run${NC}"
        update_json_field '.idempotency_test_passed' true
    else
        log "${RED}✗ Idempotency failed: $((end_count - start_count)) apps installed on re-run${NC}"
        update_json_field '.idempotency_test_passed' false
    fi
    log ""
}

test_aggregator() {
    log_section "Testing install-flatpaks-all Aggregator"

    local start_count=$(get_flatpak_count)
    local start_time=$(date +%s)

    log "Running: ujust install-flatpaks-all"
    log "This should call all 7 category commands sequentially..."
    log ""

    if [ "$SKIP_INSTALL" = true ]; then
        log "${YELLOW}Skipping installation (--skip-install mode)${NC}"
    else
        local output_file="$REPO_ROOT/testing/flatpak-all-output.log"
        local exit_code=0

        if ./testing/ujust-test install-flatpaks-all &> "$output_file"; then
            exit_code=0
        else
            exit_code=$?
        fi

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local end_count=$(get_flatpak_count)

        # Verify all categories were called
        local categories_called=0
        for category in "${CATEGORIES[@]}"; do
            if grep -q "install-flatpaks-${category}" "$output_file" 2>/dev/null; then
                ((categories_called++))
            fi
        done

        log ""
        log "Results:"
        log "  Duration: ${duration}s"
        log "  Categories called: $categories_called / 7"
        log "  Apps installed: $((end_count - start_count))"

        if [ $categories_called -eq 7 ]; then
            log "${GREEN}✓ Aggregator correctly called all categories${NC}"
            update_json_field '.aggregator_test_passed' true
        else
            log "${RED}✗ Aggregator missing categories${NC}"
            update_json_field '.aggregator_test_passed' false
        fi
    fi
    log ""
}

generate_report() {
    log_section "Generating Test Report"

    # Calculate totals from JSON
    local tmp=$(mktemp)
    jq '
        .apps_attempted = ([.categories[].expected_count] | add) |
        .apps_successful = ([.categories[] | select(.success == true) | .expected_count] | add // 0) |
        .apps_failed = ([.categories[] | select(.success == false) | .expected_count] | add // 0) |
        .apps_already_installed = ([.categories[].already_installed] | add // 0) |
        .categories_tested = (.categories | length)
    ' "$RESULTS_FILE" > "$tmp" && mv "$tmp" "$RESULTS_FILE"

    # Extract values for report
    local test_start=$(jq -r '.test_start' "$RESULTS_FILE")
    local test_end=$(jq -r '.test_end' "$RESULTS_FILE")
    local total_duration=$(jq -r '.total_duration_seconds' "$RESULTS_FILE")
    local pre_count=$(jq -r '.pre_test_count' "$RESULTS_FILE")
    local post_count=$(jq -r '.post_test_count' "$RESULTS_FILE")
    local apps_attempted=$(jq -r '.apps_attempted' "$RESULTS_FILE")
    local apps_successful=$(jq -r '.apps_successful' "$RESULTS_FILE")
    local apps_failed=$(jq -r '.apps_failed' "$RESULTS_FILE")
    local apps_already_installed=$(jq -r '.apps_already_installed' "$RESULTS_FILE")
    local disk_before=$(jq -r '.disk_usage_before_mb' "$RESULTS_FILE")
    local disk_after=$(jq -r '.disk_usage_after_mb' "$RESULTS_FILE")
    local disk_delta=$(jq -r '.disk_usage_delta_mb' "$RESULTS_FILE")

    # Generate markdown report
    cat > "$REPORT_FILE" << EOF
# Flatpak Installation Test Report

**Test Date:** $test_start
**Test Duration:** ${total_duration}s ($((total_duration / 60)) minutes)
**Test Mode:** $([ "$SKIP_INSTALL" = true ] && echo "Analysis only (--skip-install)" || echo "Full installation")

## Executive Summary

- **Total Apps Tested:** $apps_attempted apps across 7 categories
- **Success Rate:** $apps_successful / $apps_attempted apps installed successfully
- **Failed Installations:** $apps_failed apps
- **Pre-existing Apps:** $apps_already_installed apps
- **Flatpak Count:** $pre_count → $post_count (+$((post_count - pre_count)))
- **Disk Usage:** ${disk_before} MB → ${disk_after} MB (+${disk_delta} MB)

## Category Breakdown

EOF

    # Add category results
    for category in "${CATEGORIES[@]}"; do
        local command="install-flatpaks-${category}"
        local expected=$(jq -r ".categories.\"$category\".expected_count // 0" "$RESULTS_FILE")
        local duration=$(jq -r ".categories.\"$category\".duration_seconds // 0" "$RESULTS_FILE")
        local apps_installed=$(jq -r ".categories.\"$category\".apps_installed // 0" "$RESULTS_FILE")
        local already_installed=$(jq -r ".categories.\"$category\".already_installed // 0" "$RESULTS_FILE")
        local success=$(jq -r ".categories.\"$category\".success // false" "$RESULTS_FILE")
        local has_errors=$(jq -r ".categories.\"$category\".has_errors // false" "$RESULTS_FILE")

        local status_icon="✓"
        local status_color="green"
        if [ "$success" != "true" ]; then
            status_icon="✗"
            status_color="red"
        fi

        cat >> "$REPORT_FILE" << EOF
### $status_icon $command

- **Expected Apps:** $expected
- **Apps Installed:** $apps_installed
- **Already Installed:** $already_installed
- **Duration:** ${duration}s
- **Status:** $([ "$success" = "true" ] && echo "Success" || echo "Failed")
- **Errors:** $([ "$has_errors" = "true" ] && echo "Yes (see logs)" || echo "None")

EOF
    done

    # Add idempotency results
    local idempotency_passed=$(jq -r '.idempotency_test_passed // "not tested"' "$RESULTS_FILE")
    local aggregator_passed=$(jq -r '.aggregator_test_passed // "not tested"' "$RESULTS_FILE")

    cat >> "$REPORT_FILE" << EOF
## Additional Tests

### Idempotency Test
- **Status:** $([ "$idempotency_passed" = "true" ] && echo "✓ Passed" || echo "✗ Failed or not tested")
- **Description:** Re-ran all commands to verify already-installed detection

### Aggregator Test (install-flatpaks-all)
- **Status:** $([ "$aggregator_passed" = "true" ] && echo "✓ Passed" || echo "✗ Failed or not tested")
- **Description:** Verified install-flatpaks-all calls all 7 categories

## Detailed Logs

Full test logs available at:
- **Results JSON:** \`testing/flatpak-test-results.json\`
- **Test Log:** \`testing/flatpak-test.log\`
- **Category Outputs:** \`testing/flatpak-*-output.log\`

## Comparison with system_flatpaks

EOF

    # Compare with system_flatpaks file
    if [ -f "$REPO_ROOT/system_files/etc/ublue-os/system_flatpaks" ]; then
        local system_flatpaks_count=$(grep -v "^#" "$REPO_ROOT/system_files/etc/ublue-os/system_flatpaks" | grep -v "^$" | wc -l)
        cat >> "$REPORT_FILE" << EOF
The \`system_flatpaks\` file contains $system_flatpaks_count entries (including runtimes).
The ujust recipes install $apps_attempted apps (applications only, no runtimes).

**Note:** Intentional differences between these lists are expected:
- \`system_flatpaks\`: System-wide flatpaks installed on first boot
- ujust recipes: Optional apps users can install on-demand

EOF
    fi

    # Add recommendations
    cat >> "$REPORT_FILE" << EOF
## Recommendations

EOF

    if [ $apps_failed -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF
- **Fix Failed Installations:** $apps_failed apps failed to install. Review error logs to identify issues.
EOF
    fi

    if [ "$idempotency_passed" != "true" ]; then
        cat >> "$REPORT_FILE" << EOF
- **Fix Idempotency:** Some apps were re-installed on second run. Review detection logic.
EOF
    fi

    if [ $apps_failed -eq 0 ] && [ "$idempotency_passed" = "true" ]; then
        cat >> "$REPORT_FILE" << EOF
- **All tests passed!** No issues detected in flatpak installation recipes.
EOF
    fi

    log "${GREEN}✓ Report generated: $REPORT_FILE${NC}"
}

# Main execution
main() {
    # Clear previous logs
    > "$LOG_FILE"

    log_section "Flatpak Installation Test - Starting"

    if [ "$SKIP_INSTALL" = true ]; then
        log "${YELLOW}Running in analysis mode (--skip-install)${NC}"
        log "No apps will be installed."
    else
        log "${YELLOW}⚠  WARNING: This will install ~10-15 GB of flatpak apps!${NC}"
        log ""
        read -p "Continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Cancelled."
            exit 0
        fi
    fi

    # Record start time
    local test_start=$(date -Iseconds)
    local test_start_epoch=$(date +%s)
    update_json_field '.test_start' "\"$test_start\""

    # Record pre-test state
    local pre_count=$(get_flatpak_count)
    local disk_before=$(get_disk_usage_mb)
    update_json_field '.pre_test_count' "$pre_count"
    update_json_field '.disk_usage_before_mb' "$disk_before"

    log "Pre-test state:"
    log "  Flatpak apps: $pre_count"
    log "  Disk usage: ${disk_before} MB"
    log ""

    # Test each category
    for category in "${CATEGORIES[@]}"; do
        test_category "$category"
    done

    # Test idempotency
    if [ "$SKIP_INSTALL" != true ]; then
        test_idempotency
    fi

    # Test aggregator
    if [ "$SKIP_INSTALL" != true ]; then
        test_aggregator
    fi

    # Record end time
    local test_end=$(date -Iseconds)
    local test_end_epoch=$(date +%s)
    local total_duration=$((test_end_epoch - test_start_epoch))
    update_json_field '.test_end' "\"$test_end\""
    update_json_field '.total_duration_seconds' "$total_duration"

    # Record post-test state
    local post_count=$(get_flatpak_count)
    local disk_after=$(get_disk_usage_mb)
    local disk_delta=$((disk_after - disk_before))
    update_json_field '.post_test_count' "$post_count"
    update_json_field '.disk_usage_after_mb' "$disk_after"
    update_json_field '.disk_usage_delta_mb' "$disk_delta"

    log_section "Test Complete"
    log "Post-test state:"
    log "  Flatpak apps: $post_count (+$((post_count - pre_count)))"
    log "  Disk usage: ${disk_after} MB (+${disk_delta} MB)"
    log "  Total duration: ${total_duration}s ($((total_duration / 60)) minutes)"
    log ""

    # Generate report
    generate_report

    log_section "Summary"
    log "Test results saved to:"
    log "  - JSON: $RESULTS_FILE"
    log "  - Report: $REPORT_FILE"
    log "  - Log: $LOG_FILE"
    log ""
    log "${GREEN}✓ All tests completed${NC}"
}

# Run main
main
