import XCTest
import UIKit
import SwiftUI
import FoundationKit
import DesignTokensKit
@testable import MotivationDaily

@MainActor
final class AppTests: XCTestCase {

    func testBrandColorsStayOpaqueInBothAppearances() throws {
        let palette = BrandPalette.motivationDaily
        let colors: [Color] = [
            palette.background, palette.surface, palette.action,
            palette.authBackground, palette.authForeground, palette.authAction, palette.authOnAction
        ]
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for color in colors {
                let resolved = UIColor(color).resolvedColor(with: traits)
                XCTAssertEqual(resolved.cgColor.alpha, 1, accuracy: 0.001,
                               "Brand color must remain opaque")
            }
        }
    }


    // MARK: - AppRuntime Tests

    func testAppRuntime() {
        XCTAssertFalse(AppRuntime.actualVersion.isEmpty)
        XCTAssertFalse(AppRuntime.actualBuild.isEmpty)
        XCTAssertFalse(AppRuntime.version.isEmpty)
        XCTAssertFalse(AppRuntime.build.isEmpty)
        XCTAssertEqual(AppRuntime.configuration.apiBaseURL?.absoluteString, "https://api.quotable.io")
        XCTAssertTrue(AppRuntime.configuration.featureFlags.isEnabled("quotes.randomize"))
        XCTAssertTrue(AppRuntime.configuration.featureFlags.isEnabled("wallpapers.cache"))
        XCTAssertTrue(AppRuntime.configuration.featureFlags.isEnabled("offline.stubs"))
        AppRuntime.logger.log("App runtime initialized", level: .info)
        XCTAssertEqual(AppRuntime.environment, .debug)
        let now = AppRuntime.clock.now
        XCTAssertLessThanOrEqual(abs(now.timeIntervalSinceNow), 5.0)

        // Test debug overrides via UserDefaults
        UserDefaults.standard.set("9.9.9", forKey: "developer.version")
        UserDefaults.standard.set("999", forKey: "developer.build")
        defer {
            UserDefaults.standard.removeObject(forKey: "developer.version")
            UserDefaults.standard.removeObject(forKey: "developer.build")
        }
        XCTAssertEqual(AppRuntime.version, "9.9.9")
        XCTAssertEqual(AppRuntime.build, "999")

        // Test stub scenario and showcase mode resolution
        let sourceKey = "developer.source"
        let scenarioKey = "developer.scenario"
        let origSource = UserDefaults.standard.object(forKey: sourceKey)
        let origScenario = UserDefaults.standard.object(forKey: scenarioKey)
        defer {
            if let origSource { UserDefaults.standard.set(origSource, forKey: sourceKey) }
            else { UserDefaults.standard.removeObject(forKey: sourceKey) }
            if let origScenario { UserDefaults.standard.set(origScenario, forKey: scenarioKey) }
            else { UserDefaults.standard.removeObject(forKey: scenarioKey) }
        }

        UserDefaults.standard.set("stub", forKey: sourceKey)
        UserDefaults.standard.set("showcase", forKey: scenarioKey)
        XCTAssertEqual(AppRuntime.stubScenario, "showcase")
        XCTAssertTrue(AppRuntime.isShowcaseMode)

        UserDefaults.standard.set("empty", forKey: scenarioKey)
        XCTAssertEqual(AppRuntime.stubScenario, "empty")
        XCTAssertFalse(AppRuntime.isShowcaseMode)

        UserDefaults.standard.set("live", forKey: sourceKey)
        XCTAssertNil(AppRuntime.stubScenario)
    }

    // MARK: - AppContainer Tests

    func testAppContainer() {
        let container = AppContainer.live
        XCTAssertEqual(container.configuration.environment, AppRuntime.environment)
        container.logger.log("AppContainer live loaded", level: .debug)
        XCTAssertNotNil(container.localization)

        let quoteVM = container.makeQuoteViewModel()
        XCTAssertNotNil(quoteVM)

        let wallpaperVM = container.makeWallpaperViewModel()
        XCTAssertNotNil(wallpaperVM)

        let feedPageVM = container.makeFeedPageViewModel()
        XCTAssertNotNil(feedPageVM)

        let freshContainer = AppContainer()
        XCTAssertNotNil(freshContainer.makeQuoteViewModel())
    }

    #if DEBUG
    func testUITestWallpaperRepository() async throws {
        let repo = UITestWallpaperRepository()
        let catKeys: [CategoryKey?] = [
            nil,
            CategoryKey(rawValue: "inspiration"),
            CategoryKey(rawValue: "wisdom"),
            CategoryKey(rawValue: "happiness"),
            CategoryKey(rawValue: "life")
        ]
        for key in catKeys {
            let wallpaper = try await repo.generate(category: key, width: 300, height: 600)
            XCTAssertFalse(wallpaper.quote.text.isEmpty)
            XCTAssertNotNil(wallpaper.imageURL)
        }

        // Test safe clamped dimensions (<= 0)
        let clamped = try await repo.generate(category: nil, width: 0, height: -20)
        XCTAssertNotNil(clamped.imageURL)
    }

    #endif

    // MARK: - MotivationDailyApp Tests

    func testMotivationDailyApp() {
        let app = MotivationDailyApp()
        XCTAssertNotNil(app.body)
    }
}

@MainActor
final class AuthenticationFlagTests: XCTestCase {
    func testAuthenticationIsOptInAndDeveloperPreferenceIsDebugOnly() {
        let defaults = UserDefaults.standard
        let key = "developer.authentication"
        let original = defaults.object(forKey: key)
        defer {
            if let original { defaults.set(original, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        defaults.removeObject(forKey: key)
        XCTAssertFalse(AppRuntime.authenticationEnabled)
        defaults.set(true, forKey: key)
        #if DEBUG
        XCTAssertTrue(AppRuntime.authenticationEnabled)
        #else
        XCTAssertFalse(AppRuntime.authenticationEnabled)
        #endif
        defaults.set(false, forKey: key)
        XCTAssertFalse(AppRuntime.authenticationEnabled)
    }

    #if DEBUG
    func testPreviewQuoteRepositoryAndAppContainerPreview() async throws {
        let repo = PreviewQuoteRepository()
        let random = try await repo.fetchRandom()
        XCTAssertFalse(random.text.isEmpty)
        XCTAssertEqual(random.author, UITestFixtureCatalog.current.author)

        let inspirationKey = try XCTUnwrap(CategoryKey(rawValue: "inspiration"))
        let categoryQuote = try await repo.fetchByCategory(inspirationKey)
        XCTAssertEqual(categoryQuote.categoryKey, inspirationKey)

        let categories = try await repo.fetchCategories()
        XCTAssertFalse(categories.isEmpty)

        let previewContainer = AppContainer.preview
        XCTAssertNotNil(previewContainer.makeQuoteViewModel())
        XCTAssertNotNil(previewContainer.makeFeedPageViewModel())
    }
    #endif
}
