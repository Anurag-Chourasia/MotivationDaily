#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Use the caller's selected Xcode, or the validated local installation.
if [[ -z "${DEVELOPER_DIR:-}" && -d "/Applications/Xcode 27.1.app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="/Applications/Xcode 27.1.app/Contents/Developer"
fi
xcodebuild -version
xcrun --sdk iphonesimulator --show-sdk-version
command -v python3 >/dev/null
# Private packages require existing GitHub access. Never embed a token in this script.
export GIT_TERMINAL_PROMPT=0
git submodule update --init --recursive
python3 Scripts/verify_pins.py
xcodebuild -resolvePackageDependencies -project MotivationDaily.xcodeproj -scheme MotivationDaily \
    -onlyUsePackageVersionsFromResolvedFile -scmProvider system
python3 Scripts/verify_pins.py
git diff --exit-code -- '*.resolved'
xcodebuild -project MotivationDaily.xcodeproj -scheme MotivationDaily \
    -configuration "${BUILD_CONFIGURATION:-Debug}" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "${DERIVED_DATA_PATH:-$PWD/.build/bootstrap}" \
    -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution \
    -scmProvider system CODE_SIGNING_ALLOWED=NO build
