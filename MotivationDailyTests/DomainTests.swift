import XCTest
import SwiftUI
@testable import MotivationDaily

typealias Category = MotivationDaily.Category

@MainActor
final class DomainTests: XCTestCase {

    // MARK: - Category & CategoryKey Tests

    func testCategoryAndCategoryKey() {
        let key1 = CategoryKey(rawValue: "wisdom")
        let key2 = CategoryKey(rawValue: "wisdom")
        let key3 = CategoryKey(rawValue: "happiness")

        XCTAssertEqual(key1, key2)
        XCTAssertNotEqual(key1, key3)
        XCTAssertEqual(key1.rawValue, "wisdom")
        XCTAssertEqual(key1.hashValue, key2.hashValue)

        let category1 = Category(key: key1, displayName: "Wisdom", quoteCount: 42)
        let category2 = Category(key: key2, displayName: "Wisdom", quoteCount: 42)
        let category3 = Category(key: key3, displayName: "Happiness", quoteCount: 10)

        XCTAssertEqual(category1.key.rawValue, "wisdom")
        XCTAssertEqual(category1, category2)
        XCTAssertNotEqual(category1, category3)
        XCTAssertEqual(category1.displayName, "Wisdom")
        XCTAssertEqual(category1.quoteCount, 42)
    }

    // MARK: - Quote & QuoteSource Tests

    func testQuoteAndQuoteSource() throws {
        let quote = Quote(
            id: "q-123",
            text: "Knowledge speaks, but wisdom listens.",
            author: "Jimi Hendrix",
            source: .zenQuotes,
            categoryKey: CategoryKey(rawValue: "wisdom")
        )

        XCTAssertEqual(quote.id, "q-123")
        XCTAssertEqual(quote.text, "Knowledge speaks, but wisdom listens.")
        XCTAssertEqual(quote.author, "Jimi Hendrix")
        XCTAssertEqual(quote.source, .zenQuotes)
        XCTAssertEqual(quote.categoryKey?.rawValue, "wisdom")

        // Codable round-trip
        let encoder = JSONEncoder()
        let data = try encoder.encode(quote)
        let decoded = try JSONDecoder().decode(Quote.self, from: data)
        XCTAssertEqual(quote, decoded)

        XCTAssertEqual(QuoteSource.zenQuotes.rawValue, "zenQuotes")
        XCTAssertEqual(QuoteSource.quotable.rawValue, "quotable")
        XCTAssertEqual(QuoteSource.quoteGarden.rawValue, "quoteGarden")
        XCTAssertEqual(QuoteSource.adviceSlip.rawValue, "adviceSlip")
    }

    // MARK: - FavoriteQuote Tests

    func testFavoriteQuote() throws {
        let quote = Quote(
            id: "fq-1",
            text: "Be here now.",
            author: "Ram Dass",
            source: .quotable,
            categoryKey: CategoryKey(rawValue: "life")
        )
        let imageURL = URL(string: "https://picsum.photos/900/1600")!

        let fav1 = FavoriteQuote(
            from: quote,
            imageURL: imageURL,
            localImagePath: "test.jpg",
            ratioRawValue: "9:16",
            imageWidth: 900,
            imageHeight: 1600
        )

        XCTAssertEqual(fav1.id, "fq-1")
        XCTAssertEqual(fav1.text, "Be here now.")
        XCTAssertEqual(fav1.author, "Ram Dass")
        XCTAssertEqual(fav1.source, .quotable)
        XCTAssertEqual(fav1.imageURL, imageURL)
        XCTAssertEqual(fav1.localImagePath, "test.jpg")
        XCTAssertEqual(fav1.ratioRawValue, "9:16")
        XCTAssertEqual(fav1.imageWidth, 900)
        XCTAssertEqual(fav1.imageHeight, 1600)

        // Codable round-trip
        let data = try JSONEncoder().encode(fav1)
        let decoded = try JSONDecoder().decode(FavoriteQuote.self, from: data)
        XCTAssertEqual(fav1.id, decoded.id)
        XCTAssertEqual(fav1.text, decoded.text)

        // Test fallback ID when quote.id is nil
        let quoteWithoutID = Quote(id: nil, text: "Simple quote", author: nil, source: .adviceSlip, categoryKey: nil)
        let fav2 = FavoriteQuote(
            from: quoteWithoutID,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: nil,
            imageWidth: nil,
            imageHeight: nil
        )
        XCTAssertEqual(fav2.id, "Simple quote")
        XCTAssertNil(fav2.resolvedLocalImageURL)

        // Test resolvedLocalImageURL with existing local file
        let tempDir = FileManager.default.temporaryDirectory
        let sampleImageURL = tempDir.appendingPathComponent("sample.jpg")
        try Data([0xFF, 0xD8, 0xFF]).write(to: sampleImageURL)
        defer { try? FileManager.default.removeItem(at: sampleImageURL) }

        let favWithFullPath = FavoriteQuote(
            id: "full-path",
            text: "Text",
            author: "Author",
            source: .zenQuotes,
            categoryKey: nil,
            imageURL: nil,
            localImagePath: sampleImageURL.path,
            ratioRawValue: nil,
            imageWidth: nil,
            imageHeight: nil
        )
        XCTAssertNotNil(favWithFullPath.resolvedLocalImageURL)
    }

    // MARK: - ImageSource & Wallpaper Tests

    func testImageSourceAndWallpaper() throws {
        XCTAssertEqual(ImageSource.picsum.rawValue, "picsum")

        let quote = Quote(id: "w-1", text: "Walk slowly", author: "Author", source: .zenQuotes, categoryKey: nil)
        let url = URL(string: "https://example.com/wall.jpg")!
        let wallpaper = Wallpaper(
            quote: quote,
            imageURL: url,
            imageSource: .picsum,
            imageCategoryTitle: "Nature",
            seed: "abc123"
        )

        XCTAssertEqual(wallpaper.quote, quote)
        XCTAssertEqual(wallpaper.imageURL, url)
        XCTAssertEqual(wallpaper.imageSource, .picsum)
        XCTAssertEqual(wallpaper.imageCategoryTitle, "Nature")
        XCTAssertEqual(wallpaper.seed, "abc123")

        let data = try JSONEncoder().encode(wallpaper)
        let decoded = try JSONDecoder().decode(Wallpaper.self, from: data)
        XCTAssertEqual(wallpaper, decoded)
    }

    // MARK: - WallpaperAspectRatio Tests

    func testWallpaperAspectRatio() {
        XCTAssertEqual(WallpaperAspectRatio.oneToOne.rawValue, "1:1")
        XCTAssertEqual(WallpaperAspectRatio.oneToOne.id, "1:1")
        XCTAssertEqual(WallpaperAspectRatio.oneToOne.value, 1.0)
        XCTAssertEqual(WallpaperAspectRatio.oneToOne.components?.width, 1)
        XCTAssertEqual(WallpaperAspectRatio.oneToOne.components?.height, 1)

        XCTAssertEqual(WallpaperAspectRatio.sixteenToNine.rawValue, "16:9")
        XCTAssertEqual(WallpaperAspectRatio.sixteenToNine.value, 16.0 / 9.0)
        XCTAssertEqual(WallpaperAspectRatio.sixteenToNine.components?.width, 16)
        XCTAssertEqual(WallpaperAspectRatio.sixteenToNine.components?.height, 9)

        XCTAssertEqual(WallpaperAspectRatio.nineToSixteen.rawValue, "9:16")
        XCTAssertEqual(WallpaperAspectRatio.nineToSixteen.value, 9.0 / 16.0)
        XCTAssertEqual(WallpaperAspectRatio.nineToSixteen.components?.width, 9)
        XCTAssertEqual(WallpaperAspectRatio.nineToSixteen.components?.height, 16)

        XCTAssertEqual(WallpaperAspectRatio.fullScreen.rawValue, "Fullscreen")
        XCTAssertNil(WallpaperAspectRatio.fullScreen.value)
        XCTAssertNil(WallpaperAspectRatio.fullScreen.components)

        XCTAssertEqual(WallpaperAspectRatio.allCases.count, 4)
    }

    // MARK: - AccentTheme Tests

    func testAccentTheme() {
        XCTAssertEqual(AccentTheme.storageKey, "accent_theme_selection")
        XCTAssertEqual(AccentTheme.default.rawValue, "default")
        XCTAssertEqual(AccentTheme.default.displayName, "Default")
        XCTAssertEqual(AccentTheme.default.assetName, "AccentColor")
        XCTAssertEqual(AccentTheme.default.id, "default")

        XCTAssertEqual(AccentTheme.mint.rawValue, "mint")
        XCTAssertEqual(AccentTheme.mint.displayName, "Mint")
        XCTAssertEqual(AccentTheme.mint.assetName, "AccentMint")
        XCTAssertEqual(AccentTheme.mint.id, "mint")

        XCTAssertEqual(AccentTheme.ocean.rawValue, "ocean")
        XCTAssertEqual(AccentTheme.ocean.displayName, "Ocean")
        XCTAssertEqual(AccentTheme.ocean.assetName, "AccentOcean")
        XCTAssertEqual(AccentTheme.ocean.id, "ocean")

        XCTAssertEqual(AccentTheme.sunset.rawValue, "sunset")
        XCTAssertEqual(AccentTheme.sunset.displayName, "Sunset")
        XCTAssertEqual(AccentTheme.sunset.assetName, "AccentSunset")
        XCTAssertEqual(AccentTheme.sunset.id, "sunset")

        _ = AccentTheme.default.color
        _ = AccentTheme.mint.color
        _ = AccentTheme.ocean.color
        _ = AccentTheme.sunset.color

        XCTAssertEqual(AccentTheme.resolve(from: "default"), .default)
        XCTAssertEqual(AccentTheme.resolve(from: "mint"), .mint)
        XCTAssertEqual(AccentTheme.resolve(from: "ocean"), .ocean)
        XCTAssertEqual(AccentTheme.resolve(from: "sunset"), .sunset)
        XCTAssertEqual(AccentTheme.resolve(from: "invalid"), AccentTheme.default)
        XCTAssertEqual(AccentTheme.allCases.count, 4)
    }

    // MARK: - AppError Tests

    func testAppErrorDescriptionsAndRecovery() {
        let errors: [AppError] = [
            .invalidURL,
            .network(status: 401),
            .network(status: 403),
            .network(status: 404),
            .network(status: 408),
            .network(status: 429),
            .network(status: 500),
            .network(status: 503),
            .network(status: 999),
            .networkMessage("Custom network message"),
            .decoding("JSON syntax error"),
            .storage("Disk full"),
            .emptyResponse,
            .unknown("Something weird")
        ]

        for err in errors {
            XCTAssertFalse((err.errorDescription ?? "").isEmpty)
            _ = err.recoverySuggestion
        }

        XCTAssertEqual(AppError.network(status: 429).recoverySuggestion, "Try again in a few seconds.")
        XCTAssertEqual(AppError.network(status: 502).recoverySuggestion, "Please retry shortly.")
        XCTAssertEqual(AppError.network(status: 404).recoverySuggestion, "Check your network connection and retry.")
        XCTAssertEqual(AppError.emptyResponse.recoverySuggestion, "Please refresh again.")
        XCTAssertEqual(AppError.decoding("").recoverySuggestion, "Please refresh again.")
        XCTAssertEqual(AppError.storage("").recoverySuggestion, "Restart the app and try again.")
        XCTAssertNil(AppError.invalidURL.recoverySuggestion)
        XCTAssertNil(AppError.networkMessage("").recoverySuggestion)
        XCTAssertNil(AppError.unknown("").recoverySuggestion)
    }

    // MARK: - Use Cases Tests

    func testUseCases() async throws {
        let mockRepo = MockFavoritesRepository()

        // 1. AddFavoriteQuoteUseCase
        let addUseCase = AddFavoriteQuoteUseCase(favoritesRepository: mockRepo)
        let quote1 = Quote(id: "1", text: "Quote 1", author: "Author 1", source: .zenQuotes, categoryKey: nil)
        let imageData = Data([0x01, 0x02, 0x03])

        // Throws if image data is nil/empty
        XCTAssertThrowsError(try addUseCase.execute(
            quote: quote1,
            imageURL: nil,
            localImageData: nil,
            ratioRawValue: nil,
            imageWidth: nil,
            imageHeight: nil,
            existingFavorites: []
        ))
        XCTAssertThrowsError(try addUseCase.execute(
            quote: quote1,
            imageURL: nil,
            localImageData: Data(),
            ratioRawValue: nil,
            imageWidth: nil,
            imageHeight: nil,
            existingFavorites: []
        ))

        // Success addition
        let favs1 = try addUseCase.execute(
            quote: quote1,
            imageURL: URL(string: "https://example.com/1.jpg"),
            localImageData: imageData,
            ratioRawValue: "1:1",
            imageWidth: 500,
            imageHeight: 500,
            existingFavorites: []
        )
        XCTAssertEqual(favs1.count, 1)
        XCTAssertEqual(favs1.first?.id, "1")

        // Duplicate addition is ignored
        let favsDup = try addUseCase.execute(
            quote: quote1,
            imageURL: nil,
            localImageData: imageData,
            ratioRawValue: nil,
            imageWidth: nil,
            imageHeight: nil,
            existingFavorites: favs1
        )
        XCTAssertEqual(favsDup.count, 1)

        // 2. CacheFavoriteImageUseCase
        let cacheUseCase = CacheFavoriteImageUseCase(favoritesRepository: mockRepo)
        let unpopulated = FavoriteQuote(
            id: "2",
            text: "Quote 2",
            author: "A",
            source: .zenQuotes,
            categoryKey: nil,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: nil,
            imageWidth: nil,
            imageHeight: nil
        )
        let cached = try cacheUseCase.execute(quoteID: "2", imageData: imageData, existingFavorites: [unpopulated])
        XCTAssertEqual(cached.first?.localImagePath, "mock_image_2.jpg")

        // Already cached should no-op
        let noop = try cacheUseCase.execute(quoteID: "2", imageData: imageData, existingFavorites: cached)
        XCTAssertEqual(noop.first?.localImagePath, "mock_image_2.jpg")

        // Non-existent quoteID should no-op
        let missing = try cacheUseCase.execute(quoteID: "999", imageData: imageData, existingFavorites: cached)
        XCTAssertEqual(missing.count, 1)

        // 3. RemoveFavoriteQuoteUseCase
        let removeUseCase = RemoveFavoriteQuoteUseCase(favoritesRepository: mockRepo)
        let remaining = try removeUseCase.execute(quoteID: "1", existingFavorites: favs1)
        XCTAssertTrue(remaining.isEmpty)

        // Non-existent remove returns existing
        let unchanged = try removeUseCase.execute(quoteID: "not-found", existingFavorites: favs1)
        XCTAssertEqual(unchanged.count, 1)

        // 4. LoadFavoritesUseCase
        let loadUseCase = LoadFavoritesUseCase(repository: mockRepo)
        mockRepo.storedFavorites = favs1
        let loaded = try loadUseCase.execute()
        XCTAssertEqual(loaded.count, 1)

        // 5. ClearFavoritesUseCase
        let clearUseCase = ClearFavoritesUseCase(favoritesRepository: mockRepo)
        let cleared = try clearUseCase.execute()
        XCTAssertTrue(cleared.isEmpty)
        XCTAssertTrue(mockRepo.storedFavorites.isEmpty)

        // 6. FetchCategoriesUseCase
        let mockQuoteRepo = MockQuoteRepository()
        let fetchCatUseCase = FetchCategoriesUseCase(repository: mockQuoteRepo)
        let categories = try await fetchCatUseCase.execute()
        XCTAssertEqual(categories.count, 1)

        // 7. FetchWallpaperUseCase
        let mockWallRepo = MockWallpaperRepository()
        let fetchWallUseCase = FetchWallpaperUseCase(repository: mockWallRepo)
        let wallpaper = try await fetchWallUseCase.execute(category: nil, width: 300, height: 600)
        XCTAssertEqual(wallpaper.quote.text, "Mock Wallpaper Quote")
    }
}

// MARK: - Mock Repositories

final class MockFavoritesRepository: FavoritesRepository {
    var storedFavorites: [FavoriteQuote] = []
    var removedPaths: [String] = []

    func loadFavorites() throws -> [FavoriteQuote] {
        storedFavorites
    }

    func saveFavorites(_ favorites: [FavoriteQuote]) throws {
        storedFavorites = favorites
    }

    func storeImageData(_ data: Data, for quoteID: String) throws -> String {
        "mock_image_\(quoteID).jpg"
    }

    func removeImage(at localPath: String) {
        removedPaths.append(localPath)
    }
}

final class MockQuoteRepository: QuoteRepository {
    func fetchRandom() async throws -> Quote {
        Quote(id: "r1", text: "Random", author: "Author", source: .zenQuotes, categoryKey: nil)
    }

    func fetchByCategory(_ key: CategoryKey) async throws -> Quote {
        Quote(id: "c1", text: "Category Quote", author: "Author", source: .quotable, categoryKey: key)
    }

    func fetchCategories() async throws -> [Category] {
        [Category(key: CategoryKey(rawValue: "wisdom"), displayName: "Wisdom", quoteCount: 1)]
    }
}

final class MockWallpaperRepository: WallpaperRepository {
    func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper {
        Wallpaper(
            quote: Quote(id: "w1", text: "Mock Wallpaper Quote", author: "Author", source: .zenQuotes, categoryKey: category),
            imageURL: URL(string: "https://example.com/img.jpg")!,
            imageSource: .picsum,
            imageCategoryTitle: category?.rawValue,
            seed: "12345"
        )
    }
}
