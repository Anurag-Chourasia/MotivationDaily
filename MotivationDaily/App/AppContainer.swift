import Foundation
import UIKit
import FoundationKit
import LocalizationKit
import CommonNetworkingKit
import AuthKit
import AuthKitUI
import AuthKitSupabase

final class AppContainer {
    static let live = AppContainer()
    static func makeCurrent(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        favoritesOwnerID: UUID? = nil
    ) -> AppContainer {
        AppContainer(arguments: arguments, favoritesOwnerID: favoritesOwnerID)
    }
    #if DEBUG
    static var preview: AppContainer { AppContainer(arguments: ["-UITestMode"]) }
    #endif

    let localization: LocalizationController
    let configuration: AppConfiguration
    let logger: AppLogger
    let imageLoader: any ImageLoading
    let authBackendFactory: AuthBackendFactory

    let fetchCategoriesUseCase: FetchCategoriesUseCase
    let fetchWallpaperUseCase: FetchWallpaperUseCase
    let loadFavoritesUseCase: LoadFavoritesUseCase
    let addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase
    let cacheFavoriteImageUseCase: CacheFavoriteImageUseCase
    let removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase
    let clearFavoritesUseCase: ClearFavoritesUseCase
    let prefetchFeedPageUseCase: PrefetchFeedPageUseCase
    let feedCatalogueStore: FeedCatalogueStore

    init(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        favoritesDefaults: UserDefaults = .standard,
        favoritesOwnerID: UUID? = nil,
        imageLoader: (any ImageLoading)? = nil,
        authBackendFactory: @escaping AuthBackendFactory = SupabaseBackendFactory.make
    ) {
        self.authBackendFactory = authBackendFactory
        let session = APIService.makeSession()
        let imageCache = PersistentImageDataCache(
            memoryCapacityBytes: 80 * 1024 * 1024,
            diskDirectoryName: "motivationdaily.images.urlcache"
        )
        let fetcher = ImageDataFetcher(
            client: CommonNetworkingKit.HTTPClient(session: session),
            cache: imageCache
        )
        let imageDataRepository = DefaultImageDataRepository(fetcher: fetcher, cache: imageCache)
        self.imageLoader = imageLoader ?? ImageLoader(repository: imageDataRepository)
        self.localization = LocalizationController(initialLocale: .current)
        self.configuration = AppRuntime.configuration
        self.logger = AppRuntime.logger

        logger.log("Initializing AppContainer in \(configuration.environment.rawValue) mode", level: .info)

        let apiService = APIService()
        let mappingStore = CategoryMappingStore()
        let zenClient = ZenQuotesClient(apiService: apiService)
        let quotableClient = QuotableClient(apiService: apiService)
        let adviceSlipClient = AdviceSlipClient(apiService: apiService)
        let picsumFactory = PicsumURLFactory()

        self.feedCatalogueStore = Self.makeFeedCatalogueStore(
            apiService: apiService, quotableClient: quotableClient, zenClient: zenClient,
            adviceSlipClient: adviceSlipClient, arguments: arguments
        )
        let quoteRepository = Self.makeQuoteRepository(
            zenClient: zenClient, quotableClient: quotableClient, adviceSlipClient: adviceSlipClient,
            mappingStore: mappingStore, arguments: arguments
        )
        let imageRepository = DefaultImageRepository(picsumFactory: picsumFactory)
        let wallpaperRepository = Self.makeWallpaperRepository(
            quoteRepository: quoteRepository, imageRepository: imageRepository, arguments: arguments
        )
        let favoritesRepository = DefaultFavoritesRepository(
            userDefaults: favoritesDefaults, ownerID: favoritesOwnerID, logger: logger
        )

        #if DEBUG
        if arguments.contains("-UITestMode") {
            if arguments.contains("-UITestClearFavorites") {
                _ = try? ClearFavoritesUseCase(favoritesRepository: favoritesRepository).execute()
            } else {
                Self.seedUITestFavoritesIfNeeded(using: favoritesRepository)
            }
        }
        #endif

        self.fetchCategoriesUseCase = FetchCategoriesUseCase(repository: quoteRepository)
        self.fetchWallpaperUseCase = FetchWallpaperUseCase(repository: wallpaperRepository)
        self.loadFavoritesUseCase = LoadFavoritesUseCase(repository: favoritesRepository)
        self.addFavoriteQuoteUseCase = AddFavoriteQuoteUseCase(favoritesRepository: favoritesRepository)
        self.cacheFavoriteImageUseCase = CacheFavoriteImageUseCase(favoritesRepository: favoritesRepository)
        self.removeFavoriteQuoteUseCase = RemoveFavoriteQuoteUseCase(favoritesRepository: favoritesRepository)
        self.clearFavoritesUseCase = ClearFavoritesUseCase(favoritesRepository: favoritesRepository)
        self.prefetchFeedPageUseCase = PrefetchFeedPageUseCase(repository: self.feedCatalogueStore)
    }

    @MainActor
    func makeQuoteViewModel() -> QuoteViewModel {
        QuoteViewModel(
            fetchCategoriesUseCase: fetchCategoriesUseCase, loadFavoritesUseCase: loadFavoritesUseCase,
            addFavoriteQuoteUseCase: addFavoriteQuoteUseCase, cacheFavoriteImageUseCase: cacheFavoriteImageUseCase,
            removeFavoriteQuoteUseCase: removeFavoriteQuoteUseCase, clearFavoritesUseCase: clearFavoritesUseCase
        )
    }

    @MainActor
    func makeWallpaperViewModel() -> WallpaperViewModel {
        WallpaperViewModel(fetchWallpaperUseCase: fetchWallpaperUseCase, imageLoader: imageLoader)
    }

    @MainActor
    func makeFeedPageViewModel() -> FeedPageViewModel {
        FeedPageViewModel(prefetchFeedPageUseCase: prefetchFeedPageUseCase, imageLoader: imageLoader)
    }
}
