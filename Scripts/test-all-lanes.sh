#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo "       Motivation Daily Test Lanes Suite Execution          "
echo "============================================================"

TOTAL_START=$(date +%s)

run_lane() {
    local lane_name="$1"
    local script="$2"
    echo ""
    echo ">>> Running Lane: $lane_name..."
    local start=$(date +%s)
    bash "$script"
    local end=$(date +%s)
    local duration=$((end - start))
    echo ">>> Finished Lane: $lane_name in ${duration}s"
    LANE_DURATIONS+=("$lane_name: ${duration}s")
}

LANE_DURATIONS=()

run_lane "Fast Lane" "Scripts/test-fast.sh"
run_lane "UI Smoke Lane" "Scripts/test-smoke.sh"
run_lane "Performance Lane" "Scripts/test-performance.sh"
run_lane "Integration Lane" "Scripts/test-integration.sh"

TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

echo ""
echo "============================================================"
echo "             Motivation Daily Test Lane Summary             "
echo "============================================================"
for item in "${LANE_DURATIONS[@]}"; do
    echo " - $item"
done
echo "Total Execution Duration: ${TOTAL_DURATION}s"
echo "============================================================"
