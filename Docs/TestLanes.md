# Motivation Daily Test Lanes & Execution Budgets

Last updated: 3 November 2026  
Milestone: **M5 Test lanes** (Ticket IOS-22)

## 1. Overview & Lane Architecture
Motivation Daily organizes its testing into four distinct lanes to maximize pull request feedback velocity while guaranteeing full UI flow stability, snapshot pixel accuracy, and quote decoding throughput on merge and scheduled builds.

```
       ┌─────────────────────────────────────────────────────────────┐
       │                       Pull Request                          │
       │                                                             │
       │    ┌────────────────────────┐  ┌────────────────────────┐   │
       │    │       Fast Lane        │  │      UI Smoke Lane     │   │
       │    │   Unit tests & tokens  │  │ Core UI interaction    │   │
       │    │     (< 200s budget)    │  │     (< 90s budget)     │   │
       │    └────────────────────────┘  └────────────────────────┘   │
       └──────────────────────────────┬──────────────────────────────┘
                                      │
                                      ▼  Merge to main
       ┌─────────────────────────────────────────────────────────────┐
       │                Integration & Scheduled Deep Lanes           │
       │                                                             │
       │    ┌────────────────────────┐  ┌────────────────────────┐   │
       │    │    Integration Lane    │  │    Performance Lane    │   │
       │    │ Snapshots, TLS, Caches │  │ Decode & Cache metrics │   │
       │    │     (< 25m budget)     │  │     (< 45s budget)     │   │
       │    └────────────────────────┘  └────────────────────────┘   │
       └─────────────────────────────────────────────────────────────┘
```

---

## 2. Lane Mapping & Measured Durations

| Lane | Scope & Test Classes | Trigger | Measured Duration | Budget Target | Artifact Generated |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Fast Lane** | • Pinned checks (`verify_pins.py`, `verify-submodules.py`)<br>• Design tokens audit (`check_design_tokens.py`)<br>• Stub fixtures tests (`run-stub-fixtures-tests.py`)<br>• Fast unit tests: `AppTests`, `AuthenticationFlagTests`, `DataTests`, `DomainTests`, `PrivacyManifestTests`, `ViewModelTests`, `FeedIdentityTests` | Every PR & Push | ~35s (warm) / ~190s (cold) | < 200s | `MotivationDailyFast.xcresult` |
| **UI Smoke Lane** | • Core user flows (`MotivationDailyUITests`): `HomeFlowTests`, `FavoritesFlowTests`, `AboutFlowTests`, `ShareDialogTests` | Every PR & Push | ~65s | < 90s | `MotivationDailySmoke.xcresult` |
| **Integration Lane** | • Pinned snapshot baselines (`MotivationDailySnapshotTests`)<br>• Real TLS server fixtures & certificate pinning (`FailurePathTests`, `test-local-tls.py`)<br>• Presentation & view unit tests (`PresentationSharedTests`, `ViewUnitTests`)<br>• Verification suite (`verify-test-results.py`) | Merge to `main`, Scheduled, Dispatch | ~21m (full matrix) | < 25m | `MotivationDailyIntegration.xcresult` |
| **Performance Lane** | • Quote disk cache batch write & read throughput (`testQuoteDiskCacheBatchThroughput`: ~0.26s)<br>• In-memory image cache lookup & eviction (`testLightImageCacheThroughput`: ~0.47s)<br>• Quote JSON decoding throughput (`testQuoteDecodingThroughput`: ~0.25s) | Merge to `main`, Scheduled, Dispatch | ~35s | < 45s | `MotivationDailyPerformance.xcresult` |

---

## 3. CLI Script Entry Points
Developers can run any lane independently or all lanes together locally:

- **Fast Lane**: `bash Scripts/test-fast.sh`
- **UI Smoke Lane**: `bash Scripts/test-smoke.sh`
- **Integration Lane**: `bash Scripts/test-integration.sh`
- **Performance Lane**: `bash Scripts/test-performance.sh`
- **All Lanes Combined**: `bash Scripts/test-all-lanes.sh`

---

## 4. Artifact Retention & CI Diagnostics
- All test runs capture standard Xcode result bundles (`.xcresult`) via `-resultBundlePath`.
- In GitHub Actions CI, all `.xcresult` files are uploaded as run artifacts (`motivation-integration-results`) using `actions/upload-artifact@v7`.
- Snapshot diff images (`MotivationDailySnapshotTests/__Snapshots__/**/*.diff.png`) are automatically captured upon failure for immediate visual triage.
