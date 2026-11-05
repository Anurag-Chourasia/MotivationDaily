# IOS-65 — AppStubData submodule integration

All three hosts already record AppStubData as a Git submodule at `903da26b9eb10519dd7f7748f62f4801b26579fe`. This change preserves that distribution and removes Motivation Daily's additional local Swift package/module linkage.

The JSON resources remain in the submodule; the unit-test target copies its Resources folder directly into the test bundle. MotivationDailyStubProvider is now test-only and uses Bundle(for:) to decode host DTOs. No AppStubData import, product dependency or local package reference remains. ShowBook and myTV require no changes to retain the same submodule integration.

Validation on Xcode 27.1:

- 14 DataTests passed on iOS 27.0 Simulator, including positive, empty and negative fixture scenarios.
- All three Scripts/verify-submodules.py checks passed.
- TestSupport/run-stub-fixtures-tests.py checks nine resource payloads, the gitlink, absence of module linkage and test-only resource membership; it no longer compiles AppStubData as a package.
- Dependency pins, design-token checks and project plist validation passed.
- Release Simulator build passed for both architectures; inspected the built app: no AppStubData bundle, no shared Motivation fixture JSON and no MotivationDailyStubProvider symbol. The Debug test bundle contains all nine Motivation fixture JSON files.

This addresses the requested integration change. IOS-65 remains open for separate host inline fixture consolidation and AppContainer Release argument/seeding-policy acceptance criteria. No production authentication behavior changed.

## Release launch-argument isolation follow-up

AppContainer now compiles UI-test argument handling, fixture repository selection and favorites seed/clear work only in Debug. UITestWallpaperRepository and the feed catalogue UI-test snapshot/image builders are also excluded from Release. Real repositories remain the Release composition regardless of process arguments.

Seven Debug tests passed (AppTests plus the two FixtureBoundaryTests), preserving Debug fixture behavior. The two FixtureBoundaryTests passed separately in Release with ENABLE_TESTABILITY=YES: -UITestMode did not seed favorites and -UITestMode/-UITestClearFavorites preserved an existing isolated favorite. These tests use unique UserDefaults suites and do not touch personal favorites. Release artifact inspection passed with no shared fixture resources or Debug fixture symbols. This evidence is Simulator-based, not physical-device verification.

The fast lane includes FixtureBoundaryTests. CI additionally inspects the Release app and runs the focused Release configuration tests. The broader ticket remains open for inline fixture-data consolidation; these guards do not claim that all fixture data now lives in AppStubData.
