# Shared-package integration validation — 31 October 2026

## Result

The pending local integration builds with the seven pinned remote packages and
AppStubData. Validation used Xcode 27.1 and iPhone 11 / iOS 27.0 Simulator.
No commit, push, release, or remote CI execution was performed in this review.

- Debug app build: passed (`/tmp/motivation-integration-build.log`).
- Final Release app build: passed (`/tmp/motivation-release-final.log`).
- Final unit suite: 69 passed.
- Final snapshot suite: 14 passed, comparing 42 existing reference images.
- UI suite: 12 passed in the preceding full run, before the test-container isolation change.
- Fixture validation, exact package pins and submodule verification: passed.
- Workflow YAML, shell syntax and diff whitespace checks: passed.
- Result gate rejects failed/skipped snapshot suites; token guard rejects a new violation.

The initial full run failed only the favourites list/screen snapshots (six variant
assertions). They used shared application favourites. Injecting isolated UserDefaults
and fixture launch arguments into snapshot containers fixed the failures without
re-recording any reference image. Application defaults remain unchanged.

Result bundles (temporary local artifacts):

- `/tmp/motivation-integration-tests.xcresult`: initial full run; unit/UI pass, snapshots fail.
- `/tmp/motivation-isolated-tests.xcresult`: final unit/snapshot rerun; both pass.

## Changes made during review

- Added injectable container arguments and favourites storage for deterministic snapshots.
- Replaced the empty ShowBook-directory token scan with an actual MotivationDaily scan.
  An explicit baseline tracks 185 legacy violations across 66 Swift files.
- Changed CI from building test schemes to executing unit, UI and snapshot suites.
- Added result validation, snapshot-baseline preflight, Release build and artifact upload.
- Required the validated toolchain and documented runner/private-dependency prerequisites.
- Corrected stale persistence and snapshot-framework documentation.

## Remaining limits

- Remote CI, secrets, runner availability and merge protection have not been verified here.
- Snapshot destination is pinned to iPhone 11 / iOS 27.0. The app targets iOS 16.0;
  minimum-runtime and physical-device acceptance remain separate work.
- Home's synchronous reference captures only the cold-start surface. Loaded-feed behaviour
  is exercised by UI tests. Accessibility images do not prove VoiceOver focus order.
- Most visible strings still need localization migration. Legacy token violations remain.
- SwiftLint helper scripts exist, but this checkout lacks the rule/version configuration;
  SwiftLint enforcement is not claimed as part of this integration validation.
- No coverage percentage claim is made. No new baseline images were accepted.
