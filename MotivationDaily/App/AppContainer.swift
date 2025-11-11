import Foundation
import UIKit

final class AppContainer {
    static let live = AppContainer()

    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchWallpaperUseCase: FetchWallpaperUseCase
    private let loadFavoritesUseCase: LoadFavoritesUseCase
    private let addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase
    private let cacheFavoriteImageUseCase: CacheFavoriteImageUseCase
    private let removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase
    private let clearFavoritesUseCase: ClearFavoritesUseCase
    private let feedCatalogueStore: FeedCatalogueStore

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITestMode = arguments.contains("-UITestMode")

        let apiService = APIService()
        let mappingStore = CategoryMappingStore()

        let zenClient = ZenQuotesClient(apiService: apiService)
        let quotableClient = QuotableClient(apiService: apiService)
        let adviceSlipClient = AdviceSlipClient(apiService: apiService)
        let picsumFactory = PicsumURLFactory()
        if isUITestMode {
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
        if isUITestMode {
            wallpaperRepository = UITestWallpaperRepository()
        } else {
            wallpaperRepository = DefaultWallpaperRepository(
                quoteRepository: quoteRepository,
                imageRepository: imageRepository
            )
        }

        let favoritesRepository = DefaultFavoritesRepository()
        if isUITestMode {
            if arguments.contains("-UITestClearFavorites") {
                _ = try? ClearFavoritesUseCase(favoritesRepository: favoritesRepository).execute()
            } else {
                Self.seedUITestFavoritesIfNeeded(using: favoritesRepository)
            }
        }

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
        WallpaperViewModel(fetchWallpaperUseCase: fetchWallpaperUseCase)
    }

    @MainActor
    func makeFeedPageViewModel() -> FeedPageViewModel {
        FeedPageViewModel(
            catalogueStore: feedCatalogueStore
        )
    }

    private static func seedUITestFavoritesIfNeeded(using favoritesRepository: any FavoritesRepository) {
        let seedFavorite = FavoriteQuote(
            id: "uitest-seed-favorite",
            text: "Keep going. One step at a time.",
            author: "MotivationDaily",
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
}

private actor UITestWallpaperRepository: WallpaperRepository {
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
            author: "MotivationDaily",
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
        let palette: [[UIColor]] = [
            [UIColor(red: 0.07, green: 0.10, blue: 0.18, alpha: 1), UIColor(red: 0.25, green: 0.37, blue: 0.56, alpha: 1)],
            [UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1), UIColor(red: 0.34, green: 0.18, blue: 0.24, alpha: 1)],
            [UIColor(red: 0.07, green: 0.15, blue: 0.16, alpha: 1), UIColor(red: 0.12, green: 0.35, blue: 0.30, alpha: 1)],
            [UIColor(red: 0.10, green: 0.08, blue: 0.18, alpha: 1), UIColor(red: 0.24, green: 0.22, blue: 0.48, alpha: 1)]
        ]
        let seed = categoryRaw.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let colors = palette[seed % palette.count]

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
