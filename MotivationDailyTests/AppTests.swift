import XCTest
import SwiftUI
import FoundationKit
@testable import MotivationDaily

@MainActor
final class AppTests: XCTestCase {

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

    // MARK: - MotivationDailyApp Tests

    func testMotivationDailyApp() {
        let app = MotivationDailyApp()
        XCTAssertNotNil(app.body)
    }
}
