#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [Motivation Daily] Performance Lane: Cache & Decoding Throughput ==="
START_TIME=$(date +%s)

destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11,OS=27.0}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MotivationDailyPerformance.xcresult}"
rm -rf "$result"

echo "--> Running performance benchmarks on $destination..."
xcrun xcodebuild test -project MotivationDaily.xcodeproj -scheme MotivationDaily \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MotivationDailyDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:MotivationDailyTests/PerformanceTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [Motivation Daily] Performance Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
