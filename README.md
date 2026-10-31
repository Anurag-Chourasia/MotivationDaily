# Motivation Daily 🌟

A modern, fluid iOS application delivering daily inspirational quotes paired with curated, high-resolution aesthetic wallpapers. Built with SwiftUI and Swift Concurrency following Clean Architecture and MVVM principles.

---

## 📱 Features

- **Infinite Motivational Feed**: Vertical swipeable card feed with smooth transitions and real-time pre-warming.
- **Dynamic Session Randomization**: Starts on a randomized quote and wallpaper every time the app opens, preventing repetitive order while maintaining scroll stability within the session.
- **Curated Category Sections**: Switch seamlessly between categories including **Happiness**, **Inspiration**, **Life**, **Success**, **Wisdom**, and **Random**.
- **Non-Destructive Aspect Ratio Customization**: Switch wallpaper display ratios between **Fullscreen**, **1:1**, **16:9**, and **9:16** without degrading or losing the original image canvas.
- **Bookmarks & Favorites**: Save favourite quotes and wallpapers locally for offline browsing and reflection.
- **Rich Share Studio**:
  - Export beautiful composite wallpaper images with embedded typography.
  - Share wallpaper image only.
  - Share quote text only.
  - Copy quote and author directly to clipboard.
  - Save directly to Photos library.
- **Accent Theme Personalization**: Customize UI accent colors across the app.

---

## 🏗 Architecture & Tech Stack

The project adheres to **Clean Architecture + MVVM** with strict layer separation:

```mermaid
flowchart LR
    Presentation["Presentation Layer\n(SwiftUI Views & ViewModels)"] --> Domain["Domain Layer\n(Use Cases & Entities)"]
    Data["Data Layer\n(APIService, Stores, Repositories)"] --> Domain
    App["App Root\n(AppContainer & Composition)"] --> Presentation
    App --> Domain
    App --> Data
```

### Layer Breakdown
- **App (`MotivationDaily/App/`)**: Dependency injection root (`AppContainer`) wiring use cases, network services, and view models.
- **Domain (`MotivationDaily/Domain/`)**: Pure business logic containing entity models (`Quote`, `FavoriteQuote`), repository protocols, use cases, and domain error definitions. Independent of UI and external SDKs.
- **Data (`MotivationDaily/Data/`)**: Concrete implementations of repositories, network clients (`QuotableClient`, `ZenQuotesClient`, `AdviceSlipClient`), in-memory/disk caching (`FeedCatalogueStore`, `LightImageCache`), and JSON persistence.
- **Presentation (`MotivationDaily/Presentation/`)**: SwiftUI views, view models (`QuoteViewModel`, `FeedPageViewModel`), layout engines (`QuoteCardLayout`), and gesture interaction handlers.

### Technologies
- **UI Framework**: SwiftUI
- **Concurrency**: Swift Concurrency (`async`/`await`, `Task`, `actor`)
- **Minimum Target**: iOS 16.0+
- **Image Pipeline**: Custom `LightImageCache` with async image downsampling and display preparation (`preparingForDisplay()`).

---

## 📂 Project Structure

```text
Motivation Daily/
├── MotivationDaily.xcodeproj
├── MotivationDaily/
│   ├── App/
│   │   ├── MotivationDailyApp.swift
│   │   └── AppContainer.swift
│   ├── Domain/
│   │   ├── Entities/
│   │   ├── Repositories/
│   │   ├── UseCases/
│   │   └── Errors/
│   ├── Data/
│   │   ├── Catalog/
│   │   ├── Network/
│   │   └── Repositories/
│   ├── Presentation/
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   │   ├── Components/
│   │   │   ├── Favourites/
│   │   │   └── HomeView.swift
│   │   └── Shared/
│   └── Assets.xcassets
└── MotivationDailyUITests/
    ├── HomeFlowTests.swift
    └── UITestBase.swift
```

---

## Integration status

The original-image retention and relative-filename persistence fixes are implemented.
Shared networking, runtime primitives, design tokens, UI components and developer-profile
resources are wired into the app. LocalizationKit is available through the container;
most visible strings still need migration.

The design-token guard scans all 66 application Swift files. Its explicit baseline
tracks 185 existing violations; passing means no new violations, not full compliance.
Run `python3 Scripts/check_design_tokens.py` to verify. Baseline changes require review.

CI runs unit, UI and snapshot tests and checks that all three suites actually passed.
It also builds Release and uploads the result bundle. The runner needs Xcode 27.1,
an iPhone 11 simulator with iOS 27.0 (matching the visual baselines), and the private
package secrets listed in `Scripts/configure-private-dependencies.sh`. Set the repository
variable `IOS_CI_RUNNER` if the default runner does not provide that toolchain.
Remote CI execution and minimum-iOS device acceptance must be verified separately.
The Home snapshot covers its cold-start surface only; loaded-feed journeys run in
HomeFlowTests. Accessibility images are visual checks, not proof of VoiceOver order.

From this repository, run:

```sh
DEVELOPER_DIR='/Applications/Xcode 27.1.app/Contents/Developer' bash Scripts/test-integration.sh
```

Use `TEST_DESTINATION` and a fresh `TEST_RESULT_PATH` to override the destination/result.
Do not record snapshots in CI. Review changed reference images before accepting them.

---

## 🚀 Future Plans & Roadmap

### 1. Architecture & Best Engineering Practices
- **Best Engineering Practices Alignment**: Refine the Clean Architecture layer boundaries, enforce protocol abstractions, and align dependency injection with modern Swift paradigms.
- **Strict Concurrency Compliance**: Migrate towards Swift 6 strict concurrency checking (`SWIFT_STRICT_CONCURRENCY=complete`), ensuring Sendable conformance across data transfer objects and actor-isolated stores.
- **Unidirectional Data Flow (UDF)**: Refine state handling so user intents flow through explicit actions and state transitions to prevent unintended view re-renders.
- **Modularization via Custom Swift Packages (SPMs)**: Decouple monolithic targets into standalone packages (`MotivationCore`, `MotivationDomain`, `MotivationData`, `MotivationUI`, `FeatureHome`, `FeatureFavorites`) to speed up compilation and enforce architectural boundaries.

### 2. Testing & Quality Assurance
- **Comprehensive UI Testing**: Broaden automated XCUITest suites to cover all core user journeys, tab switching, sheet presentations, share actions, and error recovery states.
- **Snapshot Testing**: Expand visual regression testing using our `SnapshotTestKit` across multiple device sizes, light/dark themes, and Dynamic Type accessibility scales.
- **Stub-Data Submodules**: Create dedicated mock and fixture test submodules to provide deterministic JSON payloads and offline fixtures, fully isolating tests from live network dependencies.
- **SwiftLint Integration**: Enforce clean code guidelines, naming conventions, docstrings, and anti-pattern prevention via an SPM Build Tool plugin and pre-commit hooks.
- **Continuous Integration (CI) Pipeline**: Set up automated GitHub Actions to run matrix testing, automated builds, test-result reporting, and code quality verification on every pull request.

### 3. User Experience & Core Enhancements
- **Tab Bar Navigation**: Modernize primary app navigation into a persistent native Tab Bar (Feed, Favorites/Bookmarks, Explore/Categories, Settings) for intuitive discoverability.
- **Cross-Device Sync**: Integrate CloudKit / iCloud sync to seamlessly synchronize favorites, custom themes, and reading history across iPhone, iPad, and macOS.
- **Resilient Image Loading Pipeline**: Enhance the image loader with progressive loading, multi-CDN fallback sources, exponential backoff retries, and disk cache size governance.
- **Accessibility Support**: Ensure full VoiceOver screen reader auditing, custom accessibility actions, high contrast modes, and respectful reduced-motion accommodations for all animated transitions.
- **Performance Measurement & Telemetry**: Instrument MetricKit, `os_signpost` intervals, app launch benchmarks, scroll hitch rate monitoring, and memory footprint tracking.

### 4. iOS System Integrations & Engagement
- **WidgetKit (Home & Lock Screen Widgets)**:
  - Small, Medium, Large, and Extra Large Home Screen widgets showing the Quote of the Day with dynamic wallpaper backgrounds.
  - Circular and rectangular Lock Screen widgets with concise affirmations.
  - Interactive widgets (iOS 17+) with one-tap refresh directly from the Home Screen.
  - StandBy mode interactive display for bedside docks.
- **App Intents, Siri & Shortcuts**:
  - *"Hey Siri, motivate me"* voice command to trigger spoken or on-screen affirmations.
  - Action Button integration (iPhone 15 Pro / 16) for one-press daily quote inspiration.
  - Shortcuts actions (*"Get Daily Quote"*, *"Set Wallpaper"*) allowing users to automate morning routines.
- **Rich Interactive Notifications**:
  - Scheduled morning/evening motivation notifications with rich media previews of the wallpaper and quote typography.
  - Direct notification actions: *"Save to Favorites"* and *"Share Quote"*.

### 5. Multi-Platform Ecosystem
- **Apple Watch Companion App (watchOS)**:
  - Standalone Watch app with cached daily quotes and complications (Modular, Circular, Corner) delivering wrist-based affirmations throughout the day.
- **macOS Companion & Dynamic Wallpaper**:
  - Native macOS menu bar dropdown companion.
  - Automatic desktop wallpaper updates matching the daily motivational image.
- **iPadOS Optimization**:
  - Adaptive two-column split-view / sidebar navigation and full Stage Manager multi-window support.

### 6. Creative Studio & Personalization
- **Typography & Canvas Styling**:
  - Curated font pairings (Modern Serif, Minimalist Sans, Elegant Script, Bold Monospace).
  - Fine-grained controls for quote card opacity, backdrop blur intensity, and text alignment.
- **User Photo Backgrounds**:
  - Allow users to import personal images from their Photos library to pair with any quote.
- **Animated & Parallax Wallpapers**:
  - Gyroscope-based 3D depth parallax motion on quote cards when tilting the device.

### 7. Mindfulness & Habit Building
- **Mood & Intention Tagging**:
  - Quick mood selector (*Grateful*, *Determined*, *Calm*, *Energized*, *Reflective*) dynamically adapting the recommended feed.
- **Daily Reflection Micro-Journal**:
  - Attach a private note or personal reflection to any favorited quote.
- **Reading Streaks & Mindful Milestones**:
  - Gentle, non-intrusive habit tracking celebrating consecutive daily check-ins and reflection milestones.

### 8. Localization & Privacy
- **Localization (i18n) via String Catalogs**:
  - Multi-language quotes and interface translations (Spanish, French, German, Japanese, Hindi, etc.) using `.xcstrings`.
- **Biometric Lock (Face ID / Touch ID)**:
  - Optional biometric protection for personal favorites and private journal entries.
- **Zero-Tracker Privacy Architecture**:
  - 100% on-device processing and analytics, with zero third-party advertising trackers or data harvesting.

### 9. Technical Debt Governance (Engineering & Customer Journey)
Active technical debt backlog and tracking with dual evaluation:
- **Engineering Perspective**:
  - [x] **Eliminate absolute filesystem paths in local persistence**: Migrated `DefaultFavoritesRepository` and `FavoriteQuote` to relative filename storage with dynamic container-aware path resolution (`resolvedLocalImageURL`), fixing broken image links across container UUID updates.
  - [ ] **Decouple singleton dependencies**: Replace direct calls to `LightImageCache.shared` and `ImageLoader.shared` with protocol-injected services in view models and views.
  - [x] **Isolate live API clients from test targets**: Provide protocol-based mock adapters and offline JSON fixtures via pinned [`Submodules/AppStubData`](Submodules/AppStubData).
- **Customer Journey Perspective**:
  - [x] **Preserve original master image on custom ratio saves**: Ensure pristine, uncropped master images are saved on disk so users can freely switch aspect ratios (1:1, 16:9, 9:16, Fullscreen) inside Bookmarks/Favorites without blurriness or cropping artifacts.
  - [x] **Prevent saved favorite images from getting lost on app reopens**: Persisting stable relative image filenames ensures favorites stay intact indefinitely across app launches and sandbox container rotations.
  - [ ] **Eliminate blank card flickers during fast scrolling**: Proactive prewarming and preloading for adjacent cards in the feed.
  - [ ] **Graceful offline recovery banners**: Auto-retry quote and image fetching when network connectivity returns.

---

## 📦 Modular SPM Packages Ecosystem

`Motivation Daily` consumes modular Swift Package Manager (SPM) libraries to enforce strict separation of concerns, eliminate duplicate assets/code, and share common capabilities across apps:

| Package | Pin / Revision | Responsibility & Consumption |
| :--- | :--- | :--- |
| **`CommonNetworking`** | `1.1.0` (`c6ff2b5`) | Production HTTP networking client (`HTTPClient`) with structured request logging, response decoding, and robust error mapping used in `APIService`. |
| **`FoundationKit`** | `0.1.1` (`bb31bce`) | Core app runtime primitives (`AppConfiguration`, `BuildEnvironment`, `FeatureFlags`, `AppLogger`, `SystemClock`) orchestrated in `AppRuntime`. |
| **`LocalizationKit`** | `0.1.1` (`fdb91f3`) | Standardized localization protocol (`LocalizationProviding`) and bundled string providers injected into `AppContainer`. |
| **`DesignTokensKit`** | `1.2.0` (`511f8e6`) | Centralized typography, colors, padding, spacing, border radii, line widths, and opacity tokens across quote cards, empty states, and overlays. |
| **`UIComponentsKit`** | `1.2.0` (`0fcdd71`) | Accessible and token-driven UI widgets: `StateMessage` (empty favorites), `IconMessageBanner` (connectivity warning), and `CenteredProgressOverlay` (loading states). |
| **`DeveloperProfileKit`** | `1.0.0` (`d418170`) | Reusable `DeveloperProfileView` for the About sheet, bundling bio metadata (`DeveloperAppInfo`), contact links, and asset catalogs (`Anurag`, `CV`, `GitHub`, `LinkedIn`, `Gmail`). |
| **`SnapshotTestKit`** | `1.0.2` (`121e979`) | Cross-variant snapshot test harness (`SnapshotAssert.assertVariants`) covering Light, Dark, and Dynamic Type / Accessibility modes. |
| **`AppStubData`** | `Submodules/AppStubData` (`903da26`) | Pinned local submodule with deterministic JSON fixtures (`.positive`, `.empty`, `.negative`) for offline mock providers and tests. |

---

## 🔒 Dependency & Code Quality Governance

To prevent dependency drift, unvetted commits, and raw styling anti-patterns, the project enforces automated verification scripts:

### 1. Exact Pin Verification
Verifies the seven remote package pins against `Scripts/dependencies.json`, then checks AppStubData against its Git submodule pin:
```bash
python3 Scripts/verify_pins.py
python3 Scripts/verify-submodules.py
```

### 2. Standalone Package Dependency Tests
Tests each external dependency package independently via `swift test`:
```bash
python3 Scripts/test_dependencies.py
```

### 3. Design Token Linting
Enforces the strict rule that no view uses hardcoded colors, point dimensions, font sizes, corner radii, or padding:
```bash
python3 Scripts/check_design_tokens.py
```

### 4. Code Style & SwiftLint
Configured with dedicated scripts and CI integration:
```bash
bash Scripts/install-swiftlint.sh
bash Scripts/lint.sh
```

---

## 📦 Shared Stub Data Submodule

`Motivation Daily` integrates the shared [`AppStubData`](Submodules/AppStubData) Git submodule for deterministic offline testing and previews across `.positive`, `.empty`, and `.negative` scenarios:

```swift
import AppStubData

// Quotes fixture
let quotes = try Fixtures.data(for: .motivationDaily).endpoint(.quotes).scenario(.positive)

// Wallpapers fixture
let wallpapers = try Fixtures.data(for: .motivationDaily).endpoint(.wallpapers).scenario(.positive)
```

### Submodule Verification & Tests
Verify pinned submodule commit and test fixtures decoding:
```bash
python3 Scripts/verify-submodules.py
python3 TestSupport/run-stub-fixtures-tests.py
```

---

## 🛠 Getting Started

### Prerequisites
- macOS 14.0 or newer
- Xcode 27.1 for the validated build/test workflow
- iOS 16.0+ Simulator or Physical Device

### Building & Running
Open the project in Xcode:
```bash
open "Motivation Daily/MotivationDaily.xcodeproj"
```

Or build directly from the command line:
```bash
xcrun xcodebuild build \
  -project "Motivation Daily/MotivationDaily.xcodeproj" \
  -scheme MotivationDaily \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Running Tests

#### 1. Snapshot Tests
Verify UI components across Light, Dark, and Accessibility configurations:
```bash
xcrun xcodebuild test \
  -project "Motivation Daily/MotivationDaily.xcodeproj" \
  -scheme MotivationDailySnapshotTests \
  -destination 'platform=iOS Simulator,name=iPhone 11' \
  -only-testing:MotivationDailySnapshotTests
```

To re-record or update reference snapshots when intentional design changes occur:
```bash
RECORD_SNAPSHOTS=1 xcrun xcodebuild test \
  -project "Motivation Daily/MotivationDaily.xcodeproj" \
  -scheme MotivationDailySnapshotTests \
  -destination 'platform=iOS Simulator,name=iPhone 11' \
  -only-testing:MotivationDailySnapshotTests
```

#### 2. UI & Integration Tests
Execute automated user flow tests (`HomeFlowTests`, `FavoritesFlowTests`, `AboutFlowTests`):
```bash
xcrun xcodebuild test \
  -project "Motivation Daily/MotivationDaily.xcodeproj" \
  -scheme MotivationDailyUITests \
  -destination 'platform=iOS Simulator,name=iPhone 11'
```
