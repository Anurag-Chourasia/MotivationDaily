#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [Motivation Daily] UI Smoke Lane: Core Flows & Interactions ==="
START_TIME=$(date +%s)

# Prevent CI from recording snapshot baselines
if [[ "${CI:-}" != "" && ( "${RECORD_SNAPSHOTS:-0}" == 1 || "${SNAPSHOT_RECORD:-0}" == 1 ) ]]; then
    echo "CI cannot record snapshots" >&2; exit 1
fi

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
if [[ "$destination" =~ id=([A-Fa-f0-9-]+) ]]; then
    xcrun simctl bootstatus "${BASH_REMATCH[1]}" -b || true
fi

result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MotivationDailySmoke.xcresult}"
rm -rf "$result"

echo "--> Running UI smoke tests on $destination..."
xcrun xcodebuild test -project MotivationDaily.xcodeproj -scheme MotivationDaily \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MotivationDailyDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:MotivationDailyUITests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [Motivation Daily] UI Smoke Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
