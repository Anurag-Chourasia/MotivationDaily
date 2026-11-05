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
