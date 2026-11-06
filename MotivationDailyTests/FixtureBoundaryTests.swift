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
    #if DEBUG
    func testDebugAppCatalogMatchesPinnedTestResources() throws {
        let appURL = try XCTUnwrap(Bundle.main.url(forResource: "motivationdaily-ui-fixtures", withExtension: "json",
                                                  subdirectory: "DeveloperFixtures"))
        let testURL = try XCTUnwrap(Bundle(for: FixtureBoundaryTests.self).url(
            forResource: "motivationdaily-ui-fixtures", withExtension: "json", subdirectory: "Resources"))
        XCTAssertEqual(try Data(contentsOf: appURL), try Data(contentsOf: testURL))
        let catalog = try UITestFixtureCatalog.load()
        XCTAssertEqual(catalog.randomQuoteCount, 24)
        XCTAssertEqual(catalog.categories.map(\.key), ["focus", "growth"])
        XCTAssertEqual(catalog.gradientPalettes.count, 4)
    }

    func testMalformedOrInvalidFixtureCatalogIsRejected() throws {
        XCTAssertThrowsError(try UITestFixtureCatalog.decode(Data("{}".utf8)))
        let url = try XCTUnwrap(Bundle.main.url(forResource: "motivationdaily-ui-fixtures", withExtension: "json",
                                               subdirectory: "DeveloperFixtures"))
        var invalid = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        invalid["gradientPalettes"] = []
        XCTAssertThrowsError(try UITestFixtureCatalog.decode(JSONSerialization.data(withJSONObject: invalid)))
    }
    #endif

}
