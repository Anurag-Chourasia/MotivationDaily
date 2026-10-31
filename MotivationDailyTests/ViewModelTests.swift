import XCTest
import UIKit
import DeveloperProfileKit
@testable import MotivationDaily

@MainActor
final class ViewModelTests: XCTestCase {

    // MARK: - QuoteViewModel Tests

    func testQuoteViewModel() async throws {
        let mockRepo = MockFavoritesRepository()
        let mockQuoteRepo = MockQuoteRepository()

        let quoteVM = QuoteViewModel(
            fetchCategoriesUseCase: FetchCategoriesUseCase(repository: mockQuoteRepo),
            loadFavoritesUseCase: LoadFavoritesUseCase(repository: mockRepo),
            addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase(favoritesRepository: mockRepo),
            cacheFavoriteImageUseCase: CacheFavoriteImageUseCase(favoritesRepository: mockRepo),
            removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase(favoritesRepository: mockRepo),
            clearFavoritesUseCase: ClearFavoritesUseCase(favoritesRepository: mockRepo)
        )

        let categories = try await quoteVM.fetchCategories()
        XCTAssertEqual(categories.count, 1)

        let quote = Quote(id: "vm-q1", text: "Test Quote", author: "Tester", source: .zenQuotes, categoryKey: nil)
        let sampleImage = Data([0x01, 0x02])

        // Add
        quoteVM.addToFavorites(
            quote,
            imageURL: URL(string: "https://example.com/img.jpg"),
            localImageData: sampleImage,
            ratioRawValue: "1:1",
            imageWidth: 200,
            imageHeight: 200
        )
        XCTAssertTrue(quoteVM.isFavorited("vm-q1"))
        XCTAssertTrue(quoteVM.isFavorited(quote: quote))
        XCTAssertNotNil(quoteVM.getFavorite("vm-q1"))

        // Cache image if needed
        quoteVM.cacheFavoriteImageIfNeeded(quoteID: "vm-q1", imageData: sampleImage)
        quoteVM.cacheFavoriteImageIfNeeded(quoteID: "", imageData: sampleImage)
        quoteVM.cacheFavoriteImageIfNeeded(quoteID: "non-existent", imageData: sampleImage)

        // Remove by quote
        quoteVM.removeFromFavorites(quote: quote)
        XCTAssertFalse(quoteVM.isFavorited(quote: quote))

        // Add again and remove by ID
        quoteVM.addToFavorites(quote, localImageData: sampleImage)
        XCTAssertTrue(quoteVM.isFavorited("vm-q1"))
        quoteVM.removeFromFavorites("vm-q1")
        XCTAssertFalse(quoteVM.isFavorited("vm-q1"))

        // Clear all
        quoteVM.addToFavorites(quote, localImageData: sampleImage)
        quoteVM.clearAllFavorites()
        XCTAssertFalse(quoteVM.isFavorited("vm-q1"))

        // Edge case checks
        XCTAssertFalse(quoteVM.isFavorited(nil))
        XCTAssertFalse(quoteVM.isFavorited(quote: nil))
        XCTAssertNil(quoteVM.getFavorite("missing"))

        // Quote with nil ID matching text
        let quoteNoID = Quote(id: nil, text: "No ID Quote", author: "Author", source: .zenQuotes, categoryKey: nil)
        quoteVM.addToFavorites(quoteNoID, localImageData: sampleImage)
        XCTAssertTrue(quoteVM.isFavorited(quote: quoteNoID))
        quoteVM.removeFromFavorites(quote: quoteNoID)
        XCTAssertFalse(quoteVM.isFavorited(quote: quoteNoID))

        // Nil localImageData fails with quoteError
        quoteVM.addToFavorites(Quote(id: "no-img", text: "No Img", author: "A", source: .zenQuotes, categoryKey: nil), localImageData: nil)
        XCTAssertNotNil(quoteVM.quoteError)

        // Cache image when already has local path
        let quoteWithImg = Quote(id: "with-img", text: "Text", author: "Author", source: .zenQuotes, categoryKey: nil)
        quoteVM.addToFavorites(quoteWithImg, localImageData: sampleImage)
        quoteVM.cacheFavoriteImageIfNeeded(quoteID: "with-img", imageData: sampleImage) // Early return branch

        // removeFromFavorites(quote:) branches
        let matchTextQuote = Quote(id: "different-id", text: "Text", author: "Author", source: .zenQuotes, categoryKey: nil)
        quoteVM.removeFromFavorites(quote: matchTextQuote)

        let nonMatchQuote = Quote(id: "ghost-id", text: "Ghost Text", author: "Author", source: .zenQuotes, categoryKey: nil)
        quoteVM.removeFromFavorites(quote: nonMatchQuote)

        // isFavorited(quote:) with empty string id
        let emptyIDQuote = Quote(id: "", text: "Empty ID Quote", author: "Author", source: .zenQuotes, categoryKey: nil)
        XCTAssertFalse(quoteVM.isFavorited(quote: emptyIDQuote))
        quoteVM.addToFavorites(emptyIDQuote, localImageData: sampleImage)
        XCTAssertTrue(quoteVM.isFavorited(quote: emptyIDQuote))

        // Error branches with FailingFavoritesRepository
        let failingRepo = FailingFavoritesRepository()
        let failingVM = QuoteViewModel(
            fetchCategoriesUseCase: FetchCategoriesUseCase(repository: mockQuoteRepo),
            loadFavoritesUseCase: LoadFavoritesUseCase(repository: failingRepo),
            addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase(favoritesRepository: failingRepo),
            cacheFavoriteImageUseCase: CacheFavoriteImageUseCase(favoritesRepository: failingRepo),
            removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase(favoritesRepository: failingRepo),
            clearFavoritesUseCase: ClearFavoritesUseCase(favoritesRepository: failingRepo)
        )
        XCTAssertNotNil(failingVM.quoteError)

        failingVM.addToFavorites(quote)
        XCTAssertNotNil(failingVM.quoteError)

        failingVM.removeFromFavorites("vm-q1")
        XCTAssertNotNil(failingVM.quoteError)

        failingVM.clearAllFavorites()
        XCTAssertNotNil(failingVM.quoteError)
    }

    // MARK: - AboutViewModel Tests

    func testAboutViewModel() {
        let vm = AboutViewModel(version: "2.0.0", build: "42")
        XCTAssertEqual(vm.version, "2.0.0")
        XCTAssertEqual(vm.build, "42")
        XCTAssertEqual(vm.developerName, "Anurag Chourasia")
        XCTAssertEqual(vm.developerRole, "iOS Developer")
        XCTAssertEqual(vm.appName, "Motivation Daily")
        XCTAssertFalse(vm.appDescription.isEmpty)
        XCTAssertFalse(vm.disclaimer.isEmpty)
        XCTAssertEqual(vm.navigationTitle, "About Developer")

        let labels = vm.profileLabels
        XCTAssertEqual(labels.appInformation, "App Information")
        XCTAssertEqual(labels.version, "Version")
        XCTAssertEqual(labels.disclaimer, "Disclaimer")
    }

    // MARK: - WallpaperViewModel Tests

    func testWallpaperViewModel() async throws {
        let mockRepo = MockWallpaperRepository()
        let vm = WallpaperViewModel(fetchWallpaperUseCase: FetchWallpaperUseCase(repository: mockRepo))

        // Image request sizes for all aspect ratios
        let screen = CGSize(width: 400, height: 800)
        let s1 = vm.imageRequestSize(for: .oneToOne, screenSize: screen, scale: 2)
        XCTAssertGreaterThan(s1.width, 0)
        XCTAssertGreaterThan(s1.height, 0)
        XCTAssertEqual(s1.width, s1.height)

        let s2 = vm.imageRequestSize(for: .sixteenToNine, screenSize: screen, scale: 2)
        XCTAssertGreaterThan(s2.width, 0)

        let s3 = vm.imageRequestSize(for: .nineToSixteen, screenSize: screen, scale: 2)
        XCTAssertGreaterThan(s3.width, 0)

        let s4 = vm.imageRequestSize(for: .fullScreen, screenSize: screen, scale: 2)
        XCTAssertEqual(s4.width, 800)
        XCTAssertEqual(s4.height, 1600)

        _ = vm.imageRequestSize(for: .oneToOne)

        // Apply cached
        let quote = Quote(id: "wvm-1", text: "Text", author: "A", source: .zenQuotes, categoryKey: nil)
        let uiModel = WallpaperViewModel.WallpaperUIModel(
            quote: quote,
            imageURL: URL(string: "https://example.com/w.jpg")!,
            imageSource: .picsum,
            seed: "s",
            imageCategoryTitle: nil
        )
        let image = UIImage()
        vm.applyCached(uiModel, image: image)
        XCTAssertEqual(vm.current?.quote.id, "wvm-1")
        XCTAssertNotNil(vm.currentUIImage)

        // Set current image with matching URL
        let newImage = UIImage()
        vm.setCurrentImage(newImage, for: uiModel.imageURL)
        XCTAssertEqual(vm.currentUIImage, newImage)

        // Set current image with non-matching URL (no-op)
        vm.setCurrentImage(image, for: URL(string: "https://other.com")!)
        XCTAssertEqual(vm.currentUIImage, newImage)

        // Refresh with success (pre-cache image in LightImageCache)
        let sampleURL = URL(string: "https://example.com/img.jpg")!
        LightImageCache.shared.insert(image, for: sampleURL)

        let exp = expectation(description: "Wallpaper refresh")
        vm.refresh(category: nil, aspectRatio: .fullScreen) { result in
            switch result {
            case .success(let payload):
                XCTAssertNotNil(payload.image)
            case .failure:
                break
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 2.0)
        XCTAssertNotNil(vm.current)

        // Prefetch
        let prefetched = try await vm.prefetch(category: nil, aspectRatio: .oneToOne)
        XCTAssertNotNil(prefetched.image)

        // Refresh with failing repository
        struct FailingWallpaperRepository: WallpaperRepository {
            func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper {
                throw AppError.network(status: 500)
            }
        }
        let failingWallVM = WallpaperViewModel(fetchWallpaperUseCase: FetchWallpaperUseCase(repository: FailingWallpaperRepository()))
        let failExp = expectation(description: "Wallpaper refresh failure")
        failingWallVM.refresh(category: nil, aspectRatio: .fullScreen) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let err):
                XCTAssertNotNil(err)
            }
            failExp.fulfill()
        }
        await fulfillment(of: [failExp], timeout: 2.0)
        XCTAssertNotNil(failingWallVM.refreshError)
    }

    // MARK: - FeedPageViewModel Tests

    func testFeedPageViewModel() async throws {
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

        let pageVM = FeedPageViewModel(catalogueStore: store)
        pageVM.warmupCatalogue()

        let categories = await pageVM.categories(fallback: [])
        XCTAssertFalse(categories.isEmpty)

        let count = await pageVM.randomQuoteCount()
        XCTAssertGreaterThan(count, 0)

        // Request sizes
        let screen = CGSize(width: 375, height: 812)
        _ = pageVM.imageRequestSize(for: .fullScreen, screenSize: screen, scale: 2)
        _ = pageVM.imageRequestSize(for: .oneToOne)

        // State & cached content
        pageVM.setLoading()
        XCTAssertNil(pageVM.current)

        let quote = Quote(id: "fp-1", text: "Feed quote", author: "Author", source: .zenQuotes, categoryKey: nil)
        let sampleImage = UIImage()
        let content = FeedPageViewModel.FeedPageContent(
            quote: quote,
            image: sampleImage,
            originalImage: sampleImage,
            imageURL: URL(string: "https://example.com/feed.jpg")!,
            imageSource: .picsum,
            seed: "123",
            imageCategoryTitle: nil
        )

        pageVM.applyCached(content)
        XCTAssertEqual(pageVM.current?.quote.id, "fp-1")
        XCTAssertNil(pageVM.refreshError)

        // Invalid cache identity throws and sets refreshError
        do {
            _ = try await pageVM.loadForCurrentPage(
                category: nil,
                aspectRatio: .fullScreen,
                quoteOverride: nil,
                minimumLoaderDuration: nil,
                cacheIdentity: nil
            )
            XCTFail("Expected failure for nil cacheIdentity")
        } catch {
            XCTAssertNotNil(pageVM.refreshError)
        }

        // Load for current page using UI test store with valid cache identity
        let loaded = try await pageVM.loadForCurrentPage(
            category: nil,
            aspectRatio: .fullScreen,
            quoteOverride: nil,
            minimumLoaderDuration: nil,
            cacheIdentity: "main|d0"
        )
        XCTAssertNotNil(loaded.image)
        XCTAssertNotNil(pageVM.current)

        // Prefetch
        let prefetched = try await pageVM.prefetch(
            category: nil,
            aspectRatio: .oneToOne,
            quoteOverride: nil,
            cacheIdentity: "main|d1"
        )
        XCTAssertNotNil(prefetched.image)

        // Multiple aspect ratio sizes
        let s1 = pageVM.imageRequestSize(for: .sixteenToNine, screenSize: CGSize(width: 375, height: 812), scale: 2)
        XCTAssertGreaterThan(s1.width, 0)
        let s2 = pageVM.imageRequestSize(for: .nineToSixteen, screenSize: CGSize(width: 375, height: 812), scale: 2)
        XCTAssertGreaterThan(s2.width, 0)
    }
}

final class FailingFavoritesRepository: FavoritesRepository {
    func loadFavorites() throws -> [FavoriteQuote] {
        throw AppError.storage("Storage load failed")
    }

    func saveFavorites(_ favorites: [FavoriteQuote]) throws {
        throw AppError.storage("Storage save failed")
    }

    func storeImageData(_ data: Data, for quoteID: String) throws -> String {
        throw AppError.storage("Image store failed")
    }

    func removeImage(at localPath: String) {}
}
