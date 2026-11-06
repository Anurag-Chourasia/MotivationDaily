#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# All aliases are rejected before launching XCTest in CI.
if [[ -n "${CI:-}${GITHUB_ACTIONS:-}${TEST_RUNNER_CI:-}" ]]; then
    for alias in RECORD_SNAPSHOTS SNAPSHOT_RECORD TEST_RUNNER_SNAPSHOT_RECORD TEST_RUNNER_RECORD_SNAPSHOTS; do
        if [[ "${!alias:-0}" == 1 ]]; then
            echo "CI cannot record snapshot references ($alias)" >&2; exit 1
        fi
    done
    export TEST_RUNNER_CI=1
fi
python3 Scripts/verify-snapshot-boundary.py
python3 Scripts/verify-snapshot-baselines.py
result="${SNAPSHOT_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MotivationDailySnapshots.xcresult}"
# Keep prior evidence; callers must choose a fresh result path.
xcodebuild test -project MotivationDaily.xcodeproj -scheme MotivationDaily \
    -destination "${SNAPSHOT_DESTINATION:-platform=iOS Simulator,name=iPhone 11,OS=27.0}" \
    -testLanguage en -testRegion US -parallel-testing-enabled NO -jobs 4 \
    -derivedDataPath "${SNAPSHOT_DERIVED_DATA:-${RUNNER_TEMP:-/tmp}/MotivationDailyDerived}" \
    -resultBundlePath "$result" -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution -scmProvider system SDKROOT=iphonesimulator CODE_SIGNING_ALLOWED=NO \
    -only-testing:MotivationDailySnapshotTests/ComponentSnapshotTests
xcrun xcresulttool get test-results summary --path "$result" --compact | python3 -c '
import json,sys
summary=json.load(sys.stdin)
if summary.get("passedTests", 0) < 1 or summary.get("failedTests", 0) != 0:
    raise SystemExit("Snapshot lane did not execute successful visual comparisons")
print("Verified executed snapshot tests:", summary["passedTests"])
'
