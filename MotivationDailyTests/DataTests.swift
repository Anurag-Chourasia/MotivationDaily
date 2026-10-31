import XCTest
import UIKit
import AppStubData
@testable import MotivationDaily

@MainActor
final class DataTests: XCTestCase {

    // MARK: - CategoryMappingStore Tests

    func testCategoryMappingStore() {
        let store = CategoryMappingStore()
        let categories = store.categories()
        XCTAssertFalse(categories.isEmpty)

        let wisdomKey = CategoryKey(rawValue: "wisdom")
        let wisdomMapping = store.mapping(for: wisdomKey)
        XCTAssertNotNil(wisdomMapping)
        XCTAssertEqual(wisdomMapping?.displayName, "Wisdom")
        XCTAssertEqual(wisdomMapping?.quotableTags, "wisdom")

        let unknownKey = CategoryKey(rawValue: "unknown_category")
        XCTAssertNil(store.mapping(for: unknownKey))
    }

    // MARK: - PicsumURLFactory Tests

    func testPicsumURLFactory() {
        let factory = PicsumURLFactory()
        let url = factory.url(width: 900, height: 1600, cacheKey: nil)

        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "picsum.photos")
        XCTAssertEqual(url.path, "/900/1600")

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertTrue(queryItems?.contains { $0.name == "random" } ?? false)

        // Edge case safe width/height <= 0
        let safeUrl = factory.url(width: -10, height: 0, cacheKey: "test")
        XCTAssertEqual(safeUrl.path, "/1/1")
    }

    // MARK: - DTO Decodables Tests

    func testDTODecodables() throws {
        let decoder = JSONDecoder()

        // AdviceSlipDTO
        let adviceJSON = """
        {"slip": {"id": 101, "advice": "Remember to drink water."}}
        """.data(using: .utf8)!
        let adviceResponse = try decoder.decode(AdviceSlipResponseDTO.self, from: adviceJSON)
        XCTAssertEqual(adviceResponse.slip.id, 101)
        XCTAssertEqual(adviceResponse.slip.advice, "Remember to drink water.")

        // PicsumImageDTO
        let picsumJSON = """
        {
            "id": "10",
            "author": "Paul Jarvis",
            "width": 2500,
            "height": 1667,
            "url": "https://unsplash.com/photos/6J--NXulQCs",
            "download_url": "https://picsum.photos/id/10/2500/1667"
        }
        """.data(using: .utf8)!
        let picsum = try decoder.decode(PicsumImageDTO.self, from: picsumJSON)
        XCTAssertEqual(picsum.id, "10")
        XCTAssertEqual(picsum.author, "Paul Jarvis")
        XCTAssertEqual(picsum.width, 2500)
        XCTAssertEqual(picsum.height, 1667)
        XCTAssertEqual(picsum.downloadURL.absoluteString, "https://picsum.photos/id/10/2500/1667")

        // QuotableDTO
        let quotableJSON = """
        {"_id": "quote-1", "content": "Life is what happens.", "author": "John Lennon"}
        """.data(using: .utf8)!
        let quotable = try decoder.decode(QuotableQuoteDTO.self, from: quotableJSON)
        XCTAssertEqual(quotable._id, "quote-1")
        XCTAssertEqual(quotable.content, "Life is what happens.")
        XCTAssertEqual(quotable.author, "John Lennon")

        // QuotableCatalogDTO
        let tagJSON = """
        {"_id": "tag-1", "name": "Wisdom", "slug": "wisdom", "quoteCount": 50}
        """.data(using: .utf8)!
        let tag = try decoder.decode(QuotableTagDTO.self, from: tagJSON)
        XCTAssertEqual(tag._id, "tag-1")
        XCTAssertEqual(tag.name, "Wisdom")
        XCTAssertEqual(tag.slug, "wisdom")
        XCTAssertEqual(tag.quoteCount, 50)

        let pageJSON = """
        {
            "count": 1,
            "totalCount": 10,
            "page": 1,
            "totalPages": 10,
            "lastItemIndex": 1,
            "results": [
                {"_id": "q1", "content": "Test", "author": "Tester"}
            ]
        }
        """.data(using: .utf8)!
        let page = try decoder.decode(QuotableQuotesPageDTO.self, from: pageJSON)
        XCTAssertEqual(page.count, 1)
        XCTAssertEqual(page.totalCount, 10)
        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.totalPages, 10)
        XCTAssertEqual(page.results.count, 1)

        // ZenQuotesDTO
        let zenJSON = """
        {"q": "Peace comes from within.", "a": "Buddha"}
        """.data(using: .utf8)!
        let zen = try decoder.decode(ZenQuoteDTO.self, from: zenJSON)
        XCTAssertEqual(zen.q, "Peace comes from within.")
        XCTAssertEqual(zen.a, "Buddha")

        let zenErrorJSON = """
        {"error": "Rate limit exceeded"}
        """.data(using: .utf8)!
        let zenError = try decoder.decode(ZenErrorDTO.self, from: zenErrorJSON)
        XCTAssertEqual(zenError.error, "Rate limit exceeded")
    }

    // MARK: - MotivationDailyStubProvider Tests

    func testMotivationDailyStubProvider() throws {
        let quotes = try MotivationDailyStubProvider.loadQuotes()
        XCTAssertFalse(quotes.isEmpty)

        let authors = try MotivationDailyStubProvider.loadAuthors()
        XCTAssertFalse(authors.isEmpty)

        let wallpapers = try MotivationDailyStubProvider.loadWallpapers()
        XCTAssertFalse(wallpapers.isEmpty)
    }

    // MARK: - DefaultImageRepository Tests

    func testDefaultImageRepository() async throws {
        let repo = DefaultImageRepository(picsumFactory: PicsumURLFactory())
        let randomURL = repo.randomImageURL(width: 300, height: 600, cacheKey: nil)
        XCTAssertEqual(randomURL.host, "picsum.photos")

        let categoryURL = try await repo.imageURL(for: CategoryKey(rawValue: "life"), width: 300, height: 600, cacheKey: "life")
        XCTAssertEqual(categoryURL.host, "picsum.photos")
    }

    // MARK: - DefaultFavoritesRepository Tests

    func testDefaultFavoritesRepository() throws {
        let suiteName = "test-favorites-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let repo = DefaultFavoritesRepository(userDefaults: defaults, fileManager: .default, storageKey: "favs")

        // Load initially empty
        let initial = try repo.loadFavorites()
        XCTAssertTrue(initial.isEmpty)

        // Store image data
        let sampleData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let storedFileName = try repo.storeImageData(sampleData, for: "quote-123/special&chars")
        XCTAssertFalse(storedFileName.isEmpty)

        // Save favorites
        let quote = Quote(id: "fav-1", text: "Text", author: "Author", source: .zenQuotes, categoryKey: nil)
        let favorite = FavoriteQuote(
            from: quote,
            imageURL: nil,
            localImagePath: storedFileName,
            ratioRawValue: "1:1",
            imageWidth: 100,
            imageHeight: 100
        )
        try repo.saveFavorites([favorite])

        // Load favorites
        let loaded = try repo.loadFavorites()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, "fav-1")

        // Remove image
        repo.removeImage(at: storedFileName)
        repo.removeImage(at: "")

        // Migration from legacy absolute path
        let legacyPath = "/var/mobile/Documents/FavoriteImages/legacy-image.jpg"
        let legacyFavorite = FavoriteQuote(
            id: "legacy-1",
            text: "Legacy text",
            author: "Author",
            source: .zenQuotes,
            categoryKey: nil,
            imageURL: nil,
            localImagePath: legacyPath,
            ratioRawValue: "1:1",
            imageWidth: 100,
            imageHeight: 100
        )
        try repo.saveFavorites([legacyFavorite])
        let migrated = try repo.loadFavorites()
        XCTAssertEqual(migrated.first?.localImagePath, "legacy-image.jpg")

        // Safe filename edge cases
        let safeEmpty = try repo.storeImageData(sampleData, for: "!@#$%^&*()")
        XCTAssertFalse(safeEmpty.isEmpty)

        let veryLongID = String(repeating: "long_quote_id_", count: 10)
        let safeLong = try repo.storeImageData(sampleData, for: veryLongID)
        XCTAssertLessThanOrEqual(safeLong.count, 85) // 80 chars + .jpg

        // Corrupted UserDefaults data
        defaults.set(Data([0xFF, 0xFE, 0xFD]), forKey: "favs")
        XCTAssertThrowsError(try repo.loadFavorites())
    }

    // MARK: - DefaultWallpaperRepository Tests

    func testDefaultWallpaperRepository() async throws {
        let mockQuoteRepo = MockQuoteRepository()
        let mockImageRepo = DefaultImageRepository(picsumFactory: PicsumURLFactory())
        let wallpaperRepo = DefaultWallpaperRepository(quoteRepository: mockQuoteRepo, imageRepository: mockImageRepo)

        let randomWall = try await wallpaperRepo.generate(category: nil, width: 300, height: 600)
        XCTAssertEqual(randomWall.quote.text, "Random")
        XCTAssertEqual(randomWall.imageSource, .picsum)

        let catKey = CategoryKey(rawValue: "wisdom")
        let catWall = try await wallpaperRepo.generate(category: catKey, width: 300, height: 600)
        XCTAssertEqual(catWall.quote.text, "Category Quote")
        XCTAssertEqual(catWall.imageCategoryTitle, "wisdom")
    }

    // MARK: - APIService Tests

    func testAPIServiceMakeURL() throws {
        let apiService = APIService.shared

        let url = try apiService.makeURL(
            base: "https://example.com",
            path: "/test",
            queryItems: [URLQueryItem(name: "q", value: "hello")]
        )
        XCTAssertEqual(url.absoluteString, "https://example.com/test?q=hello")

        XCTAssertThrowsError(try apiService.makeURL(base: "https://[invalid"))
    }

    func testAPIServiceNetworking() async throws {
        let session = MockURLProtocol.makeMockSession()
        let api = APIService(session: session)
        let testURL = URL(string: "https://example.com/api/test")!

        // 1. Success 200
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "{\"key\":\"value\"}".data(using: .utf8)!)
        }
        let data = try await api.getData(testURL)
        XCTAssertFalse(data.isEmpty)

        struct TestDecodable: Decodable {
            let key: String
        }
        let decoded: TestDecodable = try await api.getDecodable(testURL)
        XCTAssertEqual(decoded.key, "value")

        // 2. 404 Status
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        do {
            _ = try await api.getData(testURL)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 3. 500 Status
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        do {
            _ = try await api.getData(testURL)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 4. Empty Response
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        do {
            _ = try await api.getData(testURL)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 5. Decoding Error
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "invalid json".data(using: .utf8)!)
        }
        do {
            let _: TestDecodable = try await api.getDecodable(testURL)
            XCTFail("Expected decoding error")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - Clients and DefaultQuoteRepository Network Tests

    func testClientsAndDefaultQuoteRepository() async throws {
        let session = MockURLProtocol.makeMockSession()
        let api = APIService(session: session)

        let adviceClient = AdviceSlipClient(apiService: api)
        let quotableClient = QuotableClient(apiService: api)
        let zenClient = ZenQuotesClient(apiService: api)
        let mappingStore = CategoryMappingStore()

        let quoteRepo = DefaultQuoteRepository(
            zenClient: zenClient,
            quotableClient: quotableClient,
            adviceSlipClient: adviceClient,
            mappingStore: mappingStore
        )

        // 1. AdviceSlipClient Success
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = "{\"slip\":{\"id\":42,\"advice\":\"Take a deep breath.\"}}"
            return (response, json.data(using: .utf8)!)
        }
        let advice = try await adviceClient.fetchRandomAdvice()
        XCTAssertEqual(advice.id, 42)
        XCTAssertEqual(advice.advice, "Take a deep breath.")

        // 2. ZenQuotesClient Success & Error & Empty
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = "[{\"q\":\"Peace begins with a smile.\",\"a\":\"Mother Teresa, type.works\"}]"
            return (response, json.data(using: .utf8)!)
        }
        let zenSingle = try await zenClient.fetchRandomQuote()
        XCTAssertEqual(zenSingle.q, "Peace begins with a smile.")

        let zenList = try await zenClient.fetchQuotes()
        XCTAssertEqual(zenList.count, 1)

        // Zen Error
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "{\"error\":\"Rate limit reached\"}".data(using: .utf8)!)
        }
        do {
            _ = try await zenClient.fetchRandomQuote()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        do {
            _ = try await zenClient.fetchQuotes()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // Zen Empty
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }
        do {
            _ = try await zenClient.fetchRandomQuote()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 3. QuotableClient Network Success & Pagination & Tags
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = """
            {
                "quotes": [
                    {"id": 1, "quote": "Wisdom is the daughter of experience.", "author": "Leonardo da Vinci"},
                    {"id": 2, "quote": "Be happy for this moment.", "author": "Omar Khayyam"}
                ],
                "total": 2
            }
            """
            return (response, json.data(using: .utf8)!)
        }
        let randomQuotable = try await quotableClient.fetchRandomQuote(tags: "wisdom")
        XCTAssertFalse(randomQuotable.content.isEmpty)

        let quotablePage = try await quotableClient.fetchQuotes(tags: "happiness", page: 1, limit: 1)
        XCTAssertEqual(quotablePage.page, 1)

        let tags = try await quotableClient.fetchTags()
        XCTAssertFalse(tags.isEmpty)

        // 4. DefaultQuoteRepository End-to-End
        // Zen success for fetchRandom
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = "[{\"q\":\"Zen random quote\",\"a\":\"Author, type.works\"}]"
            return (response, json.data(using: .utf8)!)
        }
        let randomQ = try await quoteRepo.fetchRandom()
        XCTAssertEqual(randomQ.text, "Zen random quote")
        XCTAssertEqual(randomQ.author, "Author")

        // Zen fails -> Advice slip succeeds
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            if request.url?.host?.contains("zenquotes") == true {
                return (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!, Data())
            } else {
                return (response, "{\"slip\":{\"id\":99,\"advice\":\"Advice fallback\"}}".data(using: .utf8)!)
            }
        }
        let adviceFallbackQ = try await quoteRepo.fetchRandom()
        XCTAssertEqual(adviceFallbackQ.text, "Advice fallback")

        // Both fail -> Hardcoded fallback
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let hardcodedFallbackQ = try await quoteRepo.fetchRandom()
        XCTAssertFalse(hardcodedFallbackQ.text.isEmpty)

        // By Category: Quotable succeeds
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = "{\"quotes\":[{\"id\":10,\"quote\":\"Wisdom category quote\",\"author\":\"Philosopher\"}],\"total\":1}"
            return (response, json.data(using: .utf8)!)
        }
        let wisdomCategoryQ = try await quoteRepo.fetchByCategory(CategoryKey(rawValue: "wisdom"))
        XCTAssertFalse(wisdomCategoryQ.text.isEmpty)
        XCTAssertEqual(wisdomCategoryQ.source, .quotable)

        // By Category: Quotable fails -> Hardcoded fallback
        MockURLProtocol.requestHandler = { request in
            return (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!, Data())
        }
        let catFallbackQ = try await quoteRepo.fetchByCategory(CategoryKey(rawValue: "wisdom"))
        XCTAssertFalse(catFallbackQ.text.isEmpty)

        // Unknown category
        let unknownCatQ = try await quoteRepo.fetchByCategory(CategoryKey(rawValue: "non_existent_key_xyz"))
        XCTAssertFalse(unknownCatQ.text.isEmpty)

        // Fetch categories
        let repoCategories = try await quoteRepo.fetchCategories()
        XCTAssertFalse(repoCategories.isEmpty)
    }

    // MARK: - FeedCatalogueStore Tests

    func testFeedCatalogueStore() async throws {
        let apiService = APIService.shared
        let quotable = QuotableClient(apiService: apiService)
        let zen = ZenQuotesClient(apiService: apiService)
        let advice = AdviceSlipClient(apiService: apiService)

        let store = FeedCatalogueStore.makeUITestStore(
            apiService: apiService,
            quotableClient: quotable,
            zenClient: zen,
            adviceSlipClient: advice
        )

        await store.warmup()

        let categories = await store.categories(fallback: [])
        XCTAssertFalse(categories.isEmpty)

        let randomCount = await store.randomQuoteCount()
        XCTAssertGreaterThan(randomCount, 0)

        let focusKey = CategoryKey(rawValue: "focus")
        let page = try await store.page(category: focusKey, depth: 0, quoteOverride: nil)
        XCTAssertEqual(page.quote.categoryKey, focusKey)
        XCTAssertNotNil(page.imageURL)

        let pageWithOverride = try await store.page(
            category: nil,
            depth: 1,
            quoteOverride: Quote(id: "ov", text: "Overridden", author: "None", source: .zenQuotes, categoryKey: nil)
        )
        XCTAssertEqual(pageWithOverride.quote.text, "Overridden")
    }

    func testFeedCatalogueStoreNetworkSync() async throws {
        let session = MockURLProtocol.makeMockSession()
        let api = APIService(session: session)
        let quotable = QuotableClient(apiService: api)
        let zen = ZenQuotesClient(apiService: api)
        let advice = AdviceSlipClient(apiService: api)

        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            if urlString.contains("dummyjson.com") || urlString.contains("quotable") {
                let quotes = (1...25).map {
                    "{\"id\": \($0), \"quote\": \"Wisdom quote \($0) to inspire\", \"author\": \"Author \($0)\"}"
                }.joined(separator: ",")
                let json = "{\"quotes\": [\(quotes)], \"total\": 25}"
                return (resp, json.data(using: .utf8)!)
            } else if urlString.contains("zenquotes.io") {
                let quotes = (1...25).map {
                    "{\"q\": \"Inner peace quote \($0)\", \"a\": \"Buddha \($0)\"}"
                }.joined(separator: ",")
                let json = "[\(quotes)]"
                return (resp, json.data(using: .utf8)!)
            } else if urlString.contains("adviceslip.com") {
                let json = "{\"slip\": {\"id\": 1, \"advice\": \"Always be polite.\"}}"
                return (resp, json.data(using: .utf8)!)
            } else if urlString.contains("picsum.photos") {
                if urlString.contains("page=") && !urlString.contains("page=1&") && !urlString.contains("page=1%") {
                    return (resp, "[]".data(using: .utf8)!)
                }
                let items = (1...25).map {
                    "{\"id\": \"\($0)\", \"author\": \"Photographer \($0)\", \"width\": 900, \"height\": 1600, \"url\": \"https://picsum.photos/\($0)\", \"download_url\": \"https://picsum.photos/\($0)\"}"
                }.joined(separator: ",")
                let json = "[\(items)]"
                return (resp, json.data(using: .utf8)!)
            } else {
                return (resp, Data())
            }
        }

        let cacheRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: cacheRoot) }
        let store = FeedCatalogueStore(
            apiService: api,
            quotableClient: quotable,
            zenClient: zen,
            adviceSlipClient: advice,
            cacheRootURL: cacheRoot,
            allowsNetworkSync: true
        )

        await store.warmup()
        let p1 = try await store.page(category: nil, depth: 15, quoteOverride: nil)
        XCTAssertNotNil(p1.imageURL)

        let p2 = try await store.page(category: CategoryKey(rawValue: "wisdom"), depth: 2, quoteOverride: nil)
        XCTAssertNotNil(p2.imageURL)

        let p3 = try await store.page(category: CategoryKey(rawValue: "unknown_slug"), depth: 0, quoteOverride: nil)
        XCTAssertNotNil(p3.imageURL)

        let categories = await store.categories(fallback: [Category(key: CategoryKey(rawValue: "fb"), displayName: "FB", quoteCount: nil)])
        XCTAssertFalse(categories.isEmpty)

        let randomCount = await store.randomQuoteCount()
        XCTAssertGreaterThanOrEqual(randomCount, 0)
    }
}
