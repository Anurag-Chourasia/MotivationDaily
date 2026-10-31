import XCTest
import UIKit
@testable import MotivationDaily

@MainActor
final class FailurePathTests: XCTestCase {
    private func quote(_ id: String = "q") -> Quote {
        Quote(id: id, text: "Keep learning", author: "Author", source: .zenQuotes, categoryKey: nil)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func store(snapshot: FeedCatalogueStore.Snapshot? = nil) throws -> FeedCatalogueStore {
        let api = APIService(session: MockURLProtocol.makeMockSession())
        return FeedCatalogueStore(
            apiService: api, quotableClient: QuotableClient(apiService: api),
            zenClient: ZenQuotesClient(apiService: api), adviceSlipClient: AdviceSlipClient(apiService: api),
            cacheRootURL: try temporaryDirectory(), allowsNetworkSync: false, seededSnapshot: snapshot
        )
    }

    func testAlternateQuoteFieldsAndMissingRequiredFields() throws {
        let decoder = JSONDecoder()
        let alternate = try decoder.decode(QuotableQuoteDTO.self, from: Data(#"{"id":"alt","quote":"Text","author":"A"}"#.utf8))
        XCTAssertEqual(alternate._id, "alt")
        XCTAssertEqual(alternate.content, "Text")
        for (json, missingKey) in [(#"{"content":"Text","author":"A"}"#, "_id"),
                                   (#"{"id":"alt","author":"A"}"#, "content")] {
            XCTAssertThrowsError(try decoder.decode(QuotableQuoteDTO.self, from: Data(json.utf8))) { error in
                guard case DecodingError.keyNotFound(let key, _) = error else {
                    return XCTFail("Expected missing \(missingKey), got \(error)")
                }
                XCTAssertEqual(key.stringValue, missingKey)
            }
        }
    }

    func testEmptyCatalogueUsesFallbackCategoriesAndRejectsPages() async throws {
        let catalogue = try store(snapshot: .empty())
        let fallback = [Category(key: CategoryKey(rawValue: "fallback"), displayName: "Fallback", quoteCount: nil)]
        let categories = await catalogue.categories(fallback: fallback)
        XCTAssertEqual(categories, fallback)
        let count = await catalogue.randomQuoteCount()
        XCTAssertEqual(count, 0)
        // Supplying a quote isolates the missing-image failure without any network fallback.
        do {
            _ = try await catalogue.page(category: nil, depth: 0, quoteOverride: quote())
            XCTFail("An empty image catalogue must fail")
        } catch {
            XCTAssertTrue(error is FeedCatalogueError)
        }
    }

    func testFeedRejectsMalformedCoordinatesAndCanRecoverFromFailure() async throws {
        let vm = FeedPageViewModel(catalogueStore: try store(snapshot: .empty()))
        for identity: String? in [nil, "", "lane|wrong", "lane|dNaN"] {
            do {
                _ = try await vm.loadForCurrentPage(category: nil, aspectRatio: .fullScreen, cacheIdentity: identity)
                XCTFail("Malformed coordinate must fail")
            } catch {
                XCTAssertTrue(error is FeedCatalogueError)
                XCTAssertEqual(vm.refreshError, "Could not refresh at the moment.")
                XCTAssertNil(vm.current)
            }
        }
        let image = UIImage()
        vm.applyCached(.init(quote: quote(), image: image, imageURL: URL(fileURLWithPath: "/fixture.jpg"), imageSource: .picsum, seed: "test", imageCategoryTitle: nil))
        XCTAssertEqual(vm.current?.quote.id, "q")
        XCTAssertNil(vm.refreshError)
        vm.setLoading()
        XCTAssertNil(vm.current)
    }

    func testCategoryDepthLimitAndUnknownCategoryFallback() async throws {
        let image = FeedCatalogueStore.CatalogueImageMeta(id: "image", author: "A", width: 10, height: 10, url: URL(fileURLWithPath: "/image.jpg"), downloadURL: URL(fileURLWithPath: "/image.jpg"))
        let snapshot = FeedCatalogueStore.Snapshot(
            categories: [.init(keyRawValue: "focus", displayName: "Focus", quoteCount: 1)],
            randomQuotes: [quote("random")], quotesByCategory: ["focus": [quote("focus")]],
            images: [image], updatedAt: Date()
        )
        let catalogue = try store(snapshot: snapshot)
        let page = try await catalogue.page(category: CategoryKey(rawValue: "focus"), depth: -1, quoteOverride: nil)
        XCTAssertEqual(page.quote.id, "focus")
        do {
            _ = try await catalogue.page(category: CategoryKey(rawValue: "focus"), depth: 1, quoteOverride: nil)
            XCTFail("Category depth beyond the advertised count must fail")
        } catch { XCTAssertTrue(error is FeedCatalogueError) }
        let fallback = try await catalogue.page(category: CategoryKey(rawValue: "unknown"), depth: 0, quoteOverride: nil)
        XCTAssertEqual(fallback.quote.id, "random")
    }

    func testQuotableEmptyResponseAndOutOfRangePagination() async throws {
        let session = MockURLProtocol.makeMockSession()
        defer { session.invalidateAndCancel(); MockURLProtocol.requestHandler = nil }
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(#"{"quotes":[],"total":0}"#.utf8))
        }
        let client = QuotableClient(apiService: APIService(session: session))
        do {
            _ = try await client.fetchRandomQuote(tags: "wisdom")
            XCTFail("An empty response must fail")
        } catch { XCTAssertTrue(error is AppError) }
        let page = try await client.fetchQuotes(tags: "wisdom", page: 5, limit: 0)
        XCTAssertTrue(page.results.isEmpty)
        XCTAssertEqual(page.totalPages, 1)
        XCTAssertEqual(page.count, 0)
    }

    func testImageLoaderRetriesTransientErrorsAndRejectsPermanentErrors() async throws {
        let session = MockURLProtocol.makeMockSession()
        defer { session.invalidateAndCancel(); MockURLProtocol.requestHandler = nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 5, height: 5), format: format)
        let data = try XCTUnwrap(renderer.image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 5, height: 5))
        }.pngData())
        for code in [URLError.timedOut, .networkConnectionLost, .notConnectedToInternet,
                     .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .badURL] {
            let attempts = RequestCounter()
            MockURLProtocol.requestHandler = { request in
                if attempts.increment() == 1 { throw URLError(code) }
                return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
            }
            let loader = ImageLoader(session: session)
            let url = URL(string: "https://fixture.invalid/\(UUID().uuidString).png")!
            if code == .badURL {
                do { _ = try await loader.load(url: url); XCTFail("Permanent failure must not retry") }
                catch { XCTAssertEqual((error as? URLError)?.code, .badURL) }
                XCTAssertEqual(attempts.value, 1)
            } else {
                let image = try await loader.load(url: url)
                XCTAssertEqual(image.size.width, 5)
                XCTAssertEqual(attempts.value, 2)
            }
        }
    }

    func testFavoriteImageCachingAndErrorMessages() throws {
        let repository = FaultInjectingFavoritesRepository()
        let favorite = FavoriteQuote(from: quote(), imageURL: nil, localImagePath: nil, ratioRawValue: nil, imageWidth: nil, imageHeight: nil)
        repository.favorites = [favorite]
        let vm = QuoteViewModel(
            fetchCategoriesUseCase: FetchCategoriesUseCase(repository: MockQuoteRepository()),
            loadFavoritesUseCase: LoadFavoritesUseCase(repository: repository),
            addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase(favoritesRepository: repository),
            cacheFavoriteImageUseCase: CacheFavoriteImageUseCase(favoritesRepository: repository),
            removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase(favoritesRepository: repository),
            clearFavoritesUseCase: ClearFavoritesUseCase(favoritesRepository: repository)
        )
        vm.cacheFavoriteImageIfNeeded(quoteID: "q", imageData: Data([1]))
        XCTAssertEqual(vm.getFavorite("q")?.localImagePath, "cached.jpg")
        XCTAssertEqual(repository.favorites.first?.localImagePath, "cached.jpg")
        let failures: [(Error, String)] = [(DescribedFailure(), "Storage unavailable"), (PlainFailure(), "Something went wrong.")]
        for (error, expected) in failures {
            vm.favorites = [favorite]
            repository.error = error
            vm.cacheFavoriteImageIfNeeded(quoteID: "q", imageData: Data([1]))
            XCTAssertEqual(vm.quoteError, expected)
            XCTAssertNil(vm.getFavorite("q")?.localImagePath)
            vm.removeFromFavorites("q")
            XCTAssertEqual(vm.quoteError, expected)
            XCTAssertNotNil(vm.getFavorite("q"))
        }
    }

    func testWallpaperRefreshReportsNetworkAndUnexpectedErrors() async {
        let failures: [(Error, String)] = [
            (URLError(.notConnectedToInternet), "You appear to be offline. Check your connection and try again."),
            (URLError(.timedOut), "Request timed out. Please try again."),
            (URLError(.badURL), "Could not refresh at the moment."),
            (DescribedFailure(), "Storage unavailable"),
            (PlainFailure(), "Could not refresh at the moment.")
        ]
        for (error, expected) in failures {
            let vm = WallpaperViewModel(fetchWallpaperUseCase: FetchWallpaperUseCase(repository: ErrorWallpaperRepository(error: error)))
            let completion = expectation(description: "Refresh fails with \(error)")
            vm.refresh(category: nil, aspectRatio: .fullScreen) { result in
                if case .success = result { XCTFail("Expected failure") }
                completion.fulfill()
            }
            await fulfillment(of: [completion], timeout: 2)
            XCTAssertEqual(vm.refreshError, expected)
            XCTAssertFalse(vm.isRefreshing)
            XCTAssertNil(vm.current)
        }
    }

    func testWallpaperFallsBackToRandomImageWhenCategoryImageFails() async throws {
        let images = FailingCategoryImages()
        let repository = DefaultWallpaperRepository(quoteRepository: MockQuoteRepository(), imageRepository: images)
        let wallpaper = try await repository.generate(category: CategoryKey(rawValue: "wisdom"), width: 0, height: -1)
        XCTAssertEqual(wallpaper.imageURL, images.fallback)
        XCTAssertEqual(wallpaper.quote.categoryKey?.rawValue, "wisdom")
    }

    func testAPIRejectsNonHTTPResponses() async {
        let session = MockURLProtocol.makeMockSession()
        defer { session.invalidateAndCancel(); MockURLProtocol.requestHandler = nil }
        MockURLProtocol.requestHandler = { request in
            (URLResponse(url: request.url!, mimeType: "application/json", expectedContentLength: 2, textEncodingName: nil), Data("{}".utf8))
        }
        do {
            _ = try await APIService(session: session).getData(URL(string: "https://fixture.invalid/non-http")!)
            XCTFail("Non-HTTP responses must fail")
        } catch {
            guard case AppError.networkMessage(let message) = error else { return XCTFail("Unexpected error: \(error)") }
            XCTAssertEqual(message, "Invalid response.")
        }
    }

    func testConcurrentImageLoadsShareOneRequest() async throws {
        let session = MockURLProtocol.makeMockSession()
        defer { session.invalidateAndCancel(); MockURLProtocol.requestHandler = nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let bytes = try XCTUnwrap(UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }.pngData())
        let counter = RequestCounter()
        MockURLProtocol.requestHandler = { request in
            _ = counter.increment()
            Thread.sleep(forTimeInterval: 0.05)
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, bytes)
        }
        let loader = ImageLoader(session: session)
        let url = URL(string: "https://fixture.invalid/\(UUID().uuidString)")!
        async let first = loader.load(url: url)
        async let second = loader.load(url: url)
        let (one, two) = try await (first, second)
        XCTAssertEqual(one.pngData(), two.pngData())
        XCTAssertEqual(counter.value, 1)
    }

    func testRandomCatalogueExtensionPreservesAlreadySeenPage() async throws {
        let session = MockURLProtocol.makeMockSession()
        defer { session.invalidateAndCancel(); MockURLProtocol.requestHandler = nil }
        MockURLProtocol.requestHandler = { request in
            let payload: String
            if request.url?.host == "zenquotes.io" {
                payload = "[" + (0..<25).map { "{\"q\":\"New inspiration \($0)\",\"a\":\"Author\"}" }.joined(separator: ",") + "]"
            } else if request.url?.host == "dummyjson.com" {
                payload = #"{"quotes":[],"total":0}"#
            } else { payload = "[]" }
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(payload.utf8))
        }
        let api = APIService(session: session)
        let quotes = (0..<25).map { quote("existing-\($0)") }
        let imageURL = URL(fileURLWithPath: "/fixture.jpg")
        let images = (0..<20).map { FeedCatalogueStore.CatalogueImageMeta(id: "\($0)", author: "A", width: 10, height: 10, url: imageURL, downloadURL: imageURL) }
        let catalogue = FeedCatalogueStore(apiService: api, quotableClient: QuotableClient(apiService: api), zenClient: ZenQuotesClient(apiService: api), adviceSlipClient: AdviceSlipClient(apiService: api), cacheRootURL: try temporaryDirectory(), allowsNetworkSync: true,
            seededSnapshot: .init(categories: [], randomQuotes: quotes, quotesByCategory: [FeedCatalogueStore.Snapshot.randomKey: quotes], images: images, updatedAt: Date()))
        let first = try await catalogue.page(category: nil, depth: 0, quoteOverride: nil)
        _ = try await catalogue.page(category: nil, depth: 25, quoteOverride: nil)
        let count = await catalogue.randomQuoteCount()
        XCTAssertGreaterThan(count, 25)
        let repeated = try await catalogue.page(category: nil, depth: 0, quoteOverride: nil)
        XCTAssertEqual(first.quote.id, repeated.quote.id, "Extending the feed must not reorder already seen pages")
    }

    func testFeedReportsImageFailuresWithoutInstallingStaleContent() async throws {
        let session = MockURLProtocol.makeMockSession()
        defer { session.invalidateAndCancel(); MockURLProtocol.requestHandler = nil }
        let url = URL(string: "https://fixture.invalid/\(UUID().uuidString).jpg")!
        let image = FeedCatalogueStore.CatalogueImageMeta(id: "image", author: "A", width: 10, height: 10, url: url, downloadURL: url)
        let catalogue = try store(snapshot: .init(categories: [], randomQuotes: [quote()], quotesByCategory: [FeedCatalogueStore.Snapshot.randomKey: [quote()]], images: [image], updatedAt: Date()))
        let vm = FeedPageViewModel(catalogueStore: catalogue, imageLoader: ImageLoader(session: session))
        let failures: [(URLError.Code, String)] = [
            (.notConnectedToInternet, "You appear to be offline. Check your connection and try again."),
            (.timedOut, "Request timed out. Please try again."),
            (.badURL, "Could not refresh at the moment.")
        ]
        for (code, message) in failures {
            MockURLProtocol.requestHandler = { _ in throw URLError(code) }
            do {
                _ = try await vm.loadForCurrentPage(category: nil, aspectRatio: .fullScreen, cacheIdentity: "test|d0")
                XCTFail("Image loading must fail")
            } catch {
                XCTAssertEqual((error as? URLError)?.code, code)
                XCTAssertEqual(vm.refreshError, message)
                XCTAssertNil(vm.current)
            }
        }
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!, Data())
        }
        do {
            _ = try await vm.loadForCurrentPage(category: nil, aspectRatio: .fullScreen, cacheIdentity: "test|d0")
            XCTFail("HTTP error must fail")
        } catch {
            XCTAssertEqual(vm.refreshError, AppError.network(status: 404).errorDescription)
        }
    }

    func testFavoritesEncodingAndStorageFailures() throws {
        let suite = "FailurePathTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let root = try temporaryDirectory()
        let files = IsolatedFileManager(root: root)
        let repository = DefaultFavoritesRepository(userDefaults: defaults, fileManager: files)
        let invalidDate = FavoriteQuote(from: quote(), imageURL: nil, localImagePath: nil, ratioRawValue: nil, imageWidth: nil, imageHeight: nil, savedDate: Date(timeIntervalSinceReferenceDate: .infinity))
        XCTAssertThrowsError(try repository.saveFavorites([invalidDate]))
        let images = root.appendingPathComponent("FavoriteImages")
        try FileManager.default.removeItem(at: images)
        // Replace the storage directory with a file: an actual filesystem write failure.
        try Data([1]).write(to: images)
        XCTAssertThrowsError(try repository.storeImageData(Data([1]), for: "q"))
        try FileManager.default.removeItem(at: images)
        files.failCreation = true
        XCTAssertThrowsError(try repository.storeImageData(Data([1]), for: "q"))
    }
}

private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func increment() -> Int { lock.lock(); defer { lock.unlock() }; count += 1; return count }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}

private final class IsolatedFileManager: FileManager, @unchecked Sendable {
    let root: URL
    var failCreation = false
    init(root: URL) { self.root = root; super.init() }
    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] { [root] }
    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        if failCreation { throw CocoaError(.fileWriteNoPermission) }
        try super.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
}

private struct PlainFailure: Error {}
private struct DescribedFailure: LocalizedError {
    var errorDescription: String? { "Storage unavailable" }
}

private struct ErrorWallpaperRepository: WallpaperRepository {
    let error: Error
    func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper { throw error }
}

private struct FailingCategoryImages: ImageRepository {
    let fallback = URL(string: "https://fixture.invalid/random.jpg")!
    func randomImageURL(width: Int, height: Int, cacheKey: String?) -> URL { fallback }
    func imageURL(for key: CategoryKey, width: Int, height: Int, cacheKey: String?) async throws -> URL { throw PlainFailure() }
}

private final class FaultInjectingFavoritesRepository: FavoritesRepository {
    var favorites: [FavoriteQuote] = []
    var error: Error?
    func loadFavorites() throws -> [FavoriteQuote] { favorites }
    func saveFavorites(_ favorites: [FavoriteQuote]) throws {
        if let error { throw error }
        self.favorites = favorites
    }
    func storeImageData(_ data: Data, for quoteID: String) throws -> String {
        if let error { throw error }
        return "cached.jpg"
    }
    func removeImage(at localPath: String) {}
}
