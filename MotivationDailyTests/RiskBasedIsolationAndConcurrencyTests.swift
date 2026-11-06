//
//  RiskBasedIsolationAndConcurrencyTests.swift
//  MotivationDailyTests
//
//  Risk-based isolation, migration, and concurrency coverage (IOS-23)
//

import XCTest
@testable import MotivationDaily

final class RiskBasedIsolationAndConcurrencyTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test-motivation-risk-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Account Isolation & Multi-User Favorites

    func testUserAccountSwitchingIsolatesFavoritesRepository() throws {
        let repoA = DefaultFavoritesRepository(userDefaults: defaults, ownerID: UUID())
        let repoB = DefaultFavoritesRepository(userDefaults: defaults, ownerID: UUID())

        let quoteA = Quote(id: "quote-A", text: "Courage is resistance to fear.", author: "Mark Twain", source: .zenQuotes, categoryKey: nil)
        let favoriteA = FavoriteQuote(from: quoteA, imageURL: nil, localImagePath: nil, ratioRawValue: "1:1", imageWidth: 200, imageHeight: 200)

        try repoA.saveFavorites([favoriteA])
        XCTAssertEqual(try repoA.loadFavorites().count, 1)

        // User B must start completely empty
        XCTAssertEqual(try repoB.loadFavorites().count, 0, "Account isolation: User B must not see User A favorites")

        let quoteB = Quote(id: "quote-B", text: "Simplicity is the soul of efficiency.", author: "Austin Freeman", source: .zenQuotes, categoryKey: nil)
        let favoriteB = FavoriteQuote(from: quoteB, imageURL: nil, localImagePath: nil, ratioRawValue: "1:1", imageWidth: 200, imageHeight: 200)

        try repoB.saveFavorites([favoriteB])
        XCTAssertEqual(try repoB.loadFavorites().count, 1)

        // User A remains unmodified
        let reloadedA = try repoA.loadFavorites()
        XCTAssertEqual(reloadedA.count, 1)
        XCTAssertEqual(reloadedA.first?.id, "quote-A")
    }

    // MARK: - Request Contract & Timeout Handling

    func testRequestTimeoutRejection() async {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 0.05
        let session = URLSession(configuration: config)
        let api = APIService(session: session)

        let delayedURL = URL(string: "http://10.255.255.1/nonexistent")! // Non-routable address to force timeout

        do {
            _ = try await api.getData(delayedURL)
            XCTFail("Should timeout on non-responsive host")
        } catch {
            XCTAssertTrue(error is URLError || error is AppError, "Request contract: Exceeding timeout deadline must cleanly throw")
        }
    }

    // MARK: - Demonstrated Failure & Migration Contract

    func testMigrationOfLegacyAbsolutePathsToRelativeFilenames() throws {
        let legacyPath = "/var/containers/Bundle/Application/123-ABC/Documents/FavoriteImages/legacy_quote.jpg"
        let quote = Quote(id: "legacy-migrated", text: "Stay hungry, stay foolish.", author: "Steve Jobs", source: .zenQuotes, categoryKey: nil)
        let legacyFavorite = FavoriteQuote(
            from: quote,
            imageURL: nil,
            localImagePath: legacyPath,
            ratioRawValue: "1:1",
            imageWidth: 300,
            imageHeight: 300
        )

        let repo = DefaultFavoritesRepository(userDefaults: defaults, storageKey: "favs_migration_test")
        try repo.saveFavorites([legacyFavorite])

        // Loading must dynamically normalize absolute paths to stable relative filenames
        let loaded = try repo.loadFavorites()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.localImagePath, "legacy_quote.jpg", "Migration contract: Absolute disk paths must be migrated to relative filenames")
    }
}
