#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== [Motivation Daily] Fast Lane: Static Checks & Fast Unit Tests ==="
START_TIME=$(date +%s)

# Prevent CI from recording snapshot baselines
if [[ "${CI:-}" != "" && ( "${RECORD_SNAPSHOTS:-0}" == 1 || "${SNAPSHOT_RECORD:-0}" == 1 ) ]]; then
    echo "CI cannot record snapshots" >&2; exit 1
fi

# 1. Submodules, pins, tokens, and flake quarantine
echo "--> Verifying submodules, pins, tokens, and quarantine..."
python3 Scripts/verify-submodules.py
python3 Scripts/verify_pins.py
python3 Scripts/check_design_tokens.py
python3 Scripts/test_dependencies.py
python3 Scripts/verify_flake_quarantine.py
python3 Scripts/verify-snapshot-baselines.py

# 2. Fast stub fixtures test
echo "--> Testing stub fixtures..."
python3 TestSupport/run-stub-fixtures-tests.py

# 3. Fast unit tests on iOS Simulator
destination="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 11}"
result="${TEST_RESULT_PATH:-${RUNNER_TEMP:-/tmp}/MotivationDailyFast.xcresult}"
rm -rf "$result"

echo "--> Running fast unit tests on $destination..."
xcrun xcodebuild test -project MotivationDaily.xcodeproj -scheme MotivationDaily \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/MotivationDailyDerived" \
    -resultBundlePath "$result" \
    -onlyUsePackageVersionsFromResolvedFile \
    -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO \
    -only-testing:MotivationDailyTests/AppTests \
    -only-testing:MotivationDailyTests/FixtureBoundaryTests \
    -only-testing:MotivationDailyTests/AuthenticationFlagTests \
    -only-testing:MotivationDailyTests/DataTests \
    -only-testing:MotivationDailyTests/AccountFavoritesTests \
    -only-testing:MotivationDailyTests/DomainTests \
    -only-testing:MotivationDailyTests/PrivacyManifestTests \
    -only-testing:MotivationDailyTests/ViewModelTests \
    -only-testing:MotivationDailyTests/FeedIdentityTests \
    -only-testing:MotivationDailyTests/RiskBasedIsolationAndConcurrencyTests \
    -only-testing:MotivationDailyTests/AccessibilityJourneyTests \
    -only-testing:MotivationDailyTests/LocalizationAndRTLJourneyTests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "=== [Motivation Daily] Fast Lane Succeeded in ${ELAPSED}s (Result: $result) ==="
