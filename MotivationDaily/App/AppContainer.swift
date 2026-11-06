import Foundation
import UIKit
import FoundationKit
import LocalizationKit

final class AppContainer {
    static let live = AppContainer()

    let localization: LocalizationController
    let configuration: AppConfiguration
    let logger: AppLogger
    let imageLoader: any ImageLoading

    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchWallpaperUseCase: FetchWallpaperUseCase
    private let loadFavoritesUseCase: LoadFavoritesUseCase
    private let addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase
    private let cacheFavoriteImageUseCase: CacheFavoriteImageUseCase
    private let removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase
    private let clearFavoritesUseCase: ClearFavoritesUseCase
    private let feedCatalogueStore: FeedCatalogueStore

    init(arguments: [String] = ProcessInfo.processInfo.arguments,
         favoritesDefaults: UserDefaults = .standard,
         favoritesOwnerID: UUID? = nil,
         imageLoader: any ImageLoading = ImageLoader.shared) {
        self.imageLoader = imageLoader
        self.localization = LocalizationController(initialLocale: .current)
        self.configuration = AppRuntime.configuration
        self.logger = AppRuntime.logger

        logger.log("Initializing AppContainer in \(configuration.environment.rawValue) mode", level: .info)

        #if DEBUG
        let isUITestMode = arguments.contains("-UITestMode")
        let isStubMode = isUITestMode || AppRuntime.stubScenario != nil
        #endif

        let apiService = APIService()
        let mappingStore = CategoryMappingStore()

        let zenClient = ZenQuotesClient(apiService: apiService)
        let quotableClient = QuotableClient(apiService: apiService)
        let adviceSlipClient = AdviceSlipClient(apiService: apiService)
        let picsumFactory = PicsumURLFactory()
        #if DEBUG
        if isStubMode {
            self.feedCatalogueStore = FeedCatalogueStore.makeUITestStore(
                apiService: apiService,
                quotableClient: quotableClient,
                zenClient: zenClient,
                adviceSlipClient: adviceSlipClient
            )
        } else {
            self.feedCatalogueStore = FeedCatalogueStore(
                apiService: apiService,
                quotableClient: quotableClient,
                zenClient: zenClient,
                adviceSlipClient: adviceSlipClient
            )
        }
        #else
        self.feedCatalogueStore = FeedCatalogueStore(
            apiService: apiService,
            quotableClient: quotableClient,
            zenClient: zenClient,
            adviceSlipClient: adviceSlipClient
        )
        #endif

        let quoteRepository = DefaultQuoteRepository(
            zenClient: zenClient,
            quotableClient: quotableClient,
            adviceSlipClient: adviceSlipClient,
            mappingStore: mappingStore
        )

        let imageRepository = DefaultImageRepository(
            picsumFactory: picsumFactory
        )

        let wallpaperRepository: any WallpaperRepository
        #if DEBUG
        if isStubMode {
            wallpaperRepository = UITestWallpaperRepository()
        } else {
            wallpaperRepository = DefaultWallpaperRepository(
                quoteRepository: quoteRepository,
                imageRepository: imageRepository
            )
        }
        #else
        wallpaperRepository = DefaultWallpaperRepository(
            quoteRepository: quoteRepository,
            imageRepository: imageRepository
        )
        #endif

        let favoritesRepository = DefaultFavoritesRepository(userDefaults: favoritesDefaults, ownerID: favoritesOwnerID)
        #if DEBUG
        if isUITestMode {
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
    }

    @MainActor
    func makeQuoteViewModel() -> QuoteViewModel {
        QuoteViewModel(
            fetchCategoriesUseCase: fetchCategoriesUseCase,
            loadFavoritesUseCase: loadFavoritesUseCase,
            addFavoriteQuoteUseCase: addFavoriteQuoteUseCase,
            cacheFavoriteImageUseCase: cacheFavoriteImageUseCase,
            removeFavoriteQuoteUseCase: removeFavoriteQuoteUseCase,
            clearFavoritesUseCase: clearFavoritesUseCase
        )
    }

    @MainActor
    func makeWallpaperViewModel() -> WallpaperViewModel {
        WallpaperViewModel(fetchWallpaperUseCase: fetchWallpaperUseCase, imageLoader: imageLoader)
    }

    @MainActor
    func makeFeedPageViewModel() -> FeedPageViewModel {
        FeedPageViewModel(
            catalogueStore: feedCatalogueStore,
            imageLoader: imageLoader
        )
    }

    #if DEBUG
    private static func seedUITestFavoritesIfNeeded(using favoritesRepository: any FavoritesRepository) {
        let fixture = UITestFixtureCatalog.current
        let seedFavorite = FavoriteQuote(
            id: fixture.favorite.id,
            text: fixture.favorite.text,
            author: fixture.author,
            source: .adviceSlip,
            categoryKey: nil,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "9:16",
            imageWidth: 390,
            imageHeight: 844
        )

        do {
            let existing = try favoritesRepository.loadFavorites()
            guard existing.isEmpty else { return }
            try favoritesRepository.saveFavorites([seedFavorite])
        } catch {
            try? favoritesRepository.saveFavorites([seedFavorite])
        }
    }
    #endif
}

#if DEBUG
actor UITestWallpaperRepository: WallpaperRepository {
    private var counter = 0
    private let outputDirectory: URL

    init() {
        let cacheRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = cacheRoot.appendingPathComponent("UITestWallpaperRepository", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        self.outputDirectory = directory
    }

    func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper {
        counter += 1
        let safeWidth = max(width, 1)
        let safeHeight = max(height, 1)
        let categoryRaw = category?.rawValue ?? "random"
        let quoteIndex = counter

        let quote = Quote(
            id: "uitest-\(categoryRaw)-\(quoteIndex)",
            text: "\(categoryRaw.capitalized) quote #\(quoteIndex)",
            author: UITestFixtureCatalog.current.author,
            source: category == nil ? .zenQuotes : .quotable,
            categoryKey: category
        )

        let imageURL = outputDirectory.appendingPathComponent(
            "uitest-\(categoryRaw)-\(safeWidth)x\(safeHeight)-\(quoteIndex).jpg"
        )
        try await MainActor.run {
            try Self.renderGradientImage(
                at: imageURL,
                width: safeWidth,
                height: safeHeight,
                categoryRaw: categoryRaw
            )
        }

        return Wallpaper(
            quote: quote,
            imageURL: imageURL,
            imageSource: .picsum,
            imageCategoryTitle: categoryRaw,
            seed: "uitest-\(categoryRaw)-\(quoteIndex)"
        )
    }

    @MainActor
    private static func renderGradientImage(
        at url: URL,
        width: Int,
        height: Int,
        categoryRaw: String
    ) throws {
        let size = CGSize(width: width, height: height)
        let seed = categoryRaw.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let colors = UITestFixtureCatalog.current.palette(for: seed)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [colors[0].cgColor, colors[1].cgColor] as CFArray,
                locations: [0, 1]
            ) else {
                colors[0].setFill()
                cgContext.fill(rect)
                return
            }
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw AppError.unknown("Failed to render UI test wallpaper image.")
        }
        try data.write(to: url, options: .atomic)
    }
}

#endif
