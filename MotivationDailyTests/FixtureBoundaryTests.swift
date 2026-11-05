import XCTest
@testable import MotivationDaily

@MainActor
final class FixtureBoundaryTests: XCTestCase {
    func testUITestArgumentSeedsOnlyDebugBuilds() throws {
        let suite = "fixture-boundary-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        _ = AppContainer(arguments: ["-UITestMode"], favoritesDefaults: defaults)
        let favorites = try DefaultFavoritesRepository(userDefaults: defaults).loadFavorites()
        #if DEBUG
        XCTAssertEqual(favorites.map(\.id), ["uitest-seed-favorite"])
        #else
        XCTAssertTrue(favorites.isEmpty)
        #endif
    }

    func testUITestClearArgumentOnlyClearsDebugBuilds() throws {
        let suite = "fixture-boundary-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = DefaultFavoritesRepository(userDefaults: defaults)
        let favorite = FavoriteQuote(id: "existing-user-favorite", text: "Preserve this",
                                     author: nil, source: .adviceSlip, categoryKey: nil,
                                     imageURL: nil, localImagePath: nil, ratioRawValue: nil,
                                     imageWidth: nil, imageHeight: nil)
        try repository.saveFavorites([favorite])

        _ = AppContainer(arguments: ["-UITestMode", "-UITestClearFavorites"], favoritesDefaults: defaults)
        #if DEBUG
        XCTAssertTrue(try repository.loadFavorites().isEmpty)
        #else
        XCTAssertEqual(try repository.loadFavorites(), [favorite])
        #endif
    }
}
