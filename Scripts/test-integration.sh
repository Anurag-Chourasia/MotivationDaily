#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Baselines are tied to this device/runtime; never silently choose another OS.
destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11,OS=27.0}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MotivationIntegration.xcresult}"
if [[ -e "$result" ]]; then echo "Result already exists: $result; choose TEST_RESULT_PATH" >&2; exit 1; fi
if [[ "${CI:-}" != "" && ( "${RECORD_SNAPSHOTS:-0}" == 1 || "${SNAPSHOT_RECORD:-0}" == 1 ) ]]; then
    echo "CI cannot record snapshots" >&2; exit 1
fi
python3 Scripts/verify-snapshot-baselines.py
xcodebuild -project MotivationDaily.xcodeproj -scheme MotivationDaily \
    -destination "$destination" -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MotivationIntegrationDerived" \
    -resultBundlePath "$result" -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution -scmProvider system CODE_SIGNING_ALLOWED=NO test
python3 Scripts/verify-test-results.py "$result"
