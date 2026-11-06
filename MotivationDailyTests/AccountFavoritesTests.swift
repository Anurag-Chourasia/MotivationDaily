import XCTest
@testable import MotivationDaily

@MainActor
final class AccountFavoritesTests: XCTestCase {
    private func favorite(_ id: String, path: String? = nil) -> FavoriteQuote {
        FavoriteQuote(id: id, text: id, author: nil, source: .zenQuotes, categoryKey: nil,
                      imageURL: nil, localImagePath: path, ratioRawValue: nil,
                      imageWidth: nil, imageHeight: nil)
    }

    func testMigrationPreservesBackupAndIsolatesAccountsImagesAndSignedOutStore() throws {
        let suite = "account-favorites-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: root)
        }
        let guest = DefaultFavoritesRepository(userDefaults: defaults, imagesRootURL: root)
        let originalPath = try guest.storeImageData(Data([1, 2]), for: "same-quote")
        try guest.saveFavorites([favorite("same-quote", path: originalPath)])
        let backup = try XCTUnwrap(defaults.data(forKey: "favoriteQuotes"))
        let ownerA = UUID()
        let accountA = DefaultFavoritesRepository(userDefaults: defaults, ownerID: ownerA, imagesRootURL: root)
        let migrated = try accountA.loadFavorites()
        let migratedPath = try XCTUnwrap(migrated.first?.localImagePath)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(migratedPath)), Data([1, 2]))
        XCTAssertEqual(defaults.data(forKey: "favoriteQuotes"), backup)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(originalPath).path))
        XCTAssertTrue(try guest.loadFavorites().isEmpty)

        let ownerB = UUID()
        let accountB = DefaultFavoritesRepository(userDefaults: defaults, ownerID: ownerB, imagesRootURL: root)
        XCTAssertTrue(try accountB.loadFavorites().isEmpty)
        let pathB = try accountB.storeImageData(Data([9]), for: "same-quote")
        try accountB.saveFavorites([favorite("same-quote", path: pathB)])
        XCTAssertNotEqual(pathB, migratedPath)
        accountA.removeImage(at: pathB)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(pathB)), Data([9]))
        let reopened = DefaultFavoritesRepository(userDefaults: defaults, ownerID: ownerA, imagesRootURL: root)
        XCTAssertEqual(try reopened.loadFavorites(), migrated)
        try ClearFavoritesUseCase(favoritesRepository: reopened).execute()
        XCTAssertTrue(try reopened.loadFavorites().isEmpty)
        XCTAssertEqual(try accountB.loadFavorites().count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(pathB).path))
        XCTAssertEqual(defaults.data(forKey: "favoriteQuotes"), backup)
        let laterGuestPath = try guest.storeImageData(Data([8]), for: "same-quote")
        XCTAssertNotEqual(laterGuestPath, originalPath)
        guest.removeImage(at: originalPath)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(originalPath)), Data([1, 2]))
        try guest.saveFavorites([favorite("signed-out", path: laterGuestPath)])
        XCTAssertTrue(try reopened.loadFavorites().isEmpty)
        XCTAssertEqual(try accountB.loadFavorites().map(\.id), ["same-quote"])
    }

    func testFailedImageCopyDoesNotClaimOrModifyLegacyAndRetryUsesSameOwner() throws {
        let suite = "account-favorites-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: temporary)
        }
        let image = temporary.appendingPathComponent("legacy.jpg")
        try Data([7]).write(to: image)
        let backup = try JSONEncoder().encode([favorite("legacy", path: image.path)])
        defaults.set(backup, forKey: "favoriteQuotes")
        let root = temporary.appendingPathComponent("blocked-root")
        try Data([0]).write(to: root)
        let owner = UUID()
        let repository = DefaultFavoritesRepository(userDefaults: defaults, ownerID: owner, imagesRootURL: root)
        XCTAssertThrowsError(try repository.loadFavorites())
        XCTAssertNil(defaults.data(forKey: "favoriteQuotes.owners.v1"))
        XCTAssertEqual(defaults.data(forKey: "favoriteQuotes"), backup)
        XCTAssertEqual(try Data(contentsOf: image), Data([7]))
        try FileManager.default.removeItem(at: root)
        let retried = try repository.loadFavorites()
        XCTAssertEqual(retried.map(\.id), ["legacy"])
        let path = try XCTUnwrap(retried.first?.localImagePath)
        XCTAssertTrue(path.contains(owner.uuidString.lowercased()))
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(path)), Data([7]))
    }

    func testAppContainerComposesImmutableAccountStores() throws {
        let suite = "account-composition-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let ownerA = UUID()
        let repository = DefaultFavoritesRepository(userDefaults: defaults, ownerID: ownerA)
        try repository.saveFavorites([favorite("A-only")])
        let accountA = AppContainer(arguments: [], favoritesDefaults: defaults, favoritesOwnerID: ownerA)
        let accountB = AppContainer(arguments: [], favoritesDefaults: defaults, favoritesOwnerID: UUID())
        let signedOut = AppContainer(arguments: [], favoritesDefaults: defaults)
        XCTAssertEqual(accountA.makeQuoteViewModel().favorites.map(\.id), ["A-only"])
        XCTAssertTrue(accountB.makeQuoteViewModel().favorites.isEmpty)
        XCTAssertTrue(signedOut.makeQuoteViewModel().favorites.isEmpty)
        XCTAssertEqual(accountA.makeQuoteViewModel().favorites.map(\.id), ["A-only"])
    }

    func testUnreadableOwnerMetadataIsNotOverwritten() throws {
        let suite = "account-favorites-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let corrupt = Data([0, 1, 2])
        defaults.set(corrupt, forKey: "favoriteQuotes.owners.v1")
        let repository = DefaultFavoritesRepository(userDefaults: defaults, ownerID: UUID())
        XCTAssertThrowsError(try repository.loadFavorites())
        XCTAssertThrowsError(try repository.saveFavorites([]))
        XCTAssertEqual(defaults.data(forKey: "favoriteQuotes.owners.v1"), corrupt)
        defaults.set("invalid type", forKey: "favoriteQuotes.owners.v1")
        XCTAssertThrowsError(try repository.saveFavorites([]))
        XCTAssertEqual(defaults.string(forKey: "favoriteQuotes.owners.v1"), "invalid type")
    }
}
