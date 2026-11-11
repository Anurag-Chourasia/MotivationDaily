import LocalizationKit
import SwiftUI
import UIKit
import Combine

@MainActor
final class FeedPageViewModel: ObservableObject {
    struct FeedPageContent {
        let quote: Quote
        let image: UIImage
        let originalImage: UIImage
        let imageURL: URL
        let imageSource: ImageSource
        let seed: String
        let imageCategoryTitle: String?

        init(
            quote: Quote,
            image: UIImage,
            originalImage: UIImage? = nil,
            imageURL: URL,
            imageSource: ImageSource,
            seed: String,
            imageCategoryTitle: String?
        ) {
            self.quote = quote
            self.image = image
            self.originalImage = originalImage ?? image
            self.imageURL = imageURL
            self.imageSource = imageSource
            self.seed = seed
            self.imageCategoryTitle = imageCategoryTitle
        }
    }

    enum FeedPageState {
        case loading
        case ready(FeedPageContent)
    }

    @Published private(set) var state: FeedPageState = .loading
    @Published var refreshError: String?

    var current: FeedPageContent? {
        guard case .ready(let content) = state else { return nil }
        return content
    }

    private let prefetchFeedPageUseCase: PrefetchFeedPageUseCase
    let imageLoader: any ImageLoading
    private var inFlightTasks: [String: Task<FeedPageContent, Error>] = [:]

    init(prefetchFeedPageUseCase: PrefetchFeedPageUseCase, imageLoader: any ImageLoading = ImageLoader.shared) {
        self.prefetchFeedPageUseCase = prefetchFeedPageUseCase
        self.imageLoader = imageLoader
    }

    convenience init(catalogueStore: any FeedCatalogueRepository, imageLoader: any ImageLoading = ImageLoader.shared) {
        self.init(prefetchFeedPageUseCase: PrefetchFeedPageUseCase(repository: catalogueStore), imageLoader: imageLoader)
    }

    func applyCached(_ content: FeedPageContent) {
        refreshError = nil
        state = .ready(content)
    }

    func setLoading() {
        refreshError = nil
        state = .loading
    }

    func loadForCurrentPage(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        quoteOverride: Quote? = nil,
        minimumLoaderDuration: TimeInterval? = nil,
        cacheIdentity: String? = nil
    ) async throws -> FeedPageContent {
        setLoading()
        do {
            let content = try await loadContent(
                category: category,
                aspectRatio: aspectRatio,
                quoteOverride: quoteOverride,
                minimumLoaderDuration: minimumLoaderDuration,
                cacheIdentity: cacheIdentity
            )
            state = .ready(content)
            return content
        } catch {
            refreshError = userFacingMessage(for: error)
            throw error
        }
    }

    func prefetch(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        quoteOverride: Quote? = nil,
        cacheIdentity: String? = nil
    ) async throws -> FeedPageContent {
        try await loadContent(
            category: category,
            aspectRatio: aspectRatio,
            quoteOverride: quoteOverride,
            minimumLoaderDuration: nil,
            cacheIdentity: cacheIdentity
        )
    }

    func warmupCatalogue() {
        Task {
            await prefetchFeedPageUseCase.warmup()
        }
    }

    func categories(fallback: [Category]) async -> [Category] {
        await prefetchFeedPageUseCase.categories(fallback: fallback)
    }

    func randomQuoteCount() async -> Int {
        await prefetchFeedPageUseCase.randomQuoteCount()
    }

    func imageRequestSize(for aspectRatio: WallpaperAspectRatio) -> (width: Int, height: Int) {
        imageRequestSize(
            for: aspectRatio,
            screenSize: UIScreen.main.bounds.size,
            scale: UIScreen.main.scale
        )
    }

    func imageRequestSize(
        for aspectRatio: WallpaperAspectRatio,
        screenSize: CGSize,
        scale: CGFloat
    ) -> (width: Int, height: Int) {
        let safeScale = max(scale, 1)
        let screenWidth = max(screenSize.width * safeScale, 1)
        let screenHeight = max(screenSize.height * safeScale, 1)

        guard let ratio = aspectRatio.components else {
            return (width: Int(ceil(screenWidth)), height: Int(ceil(screenHeight)))
        }

        let multiplier = min(screenWidth / ratio.width, screenHeight / ratio.height)
        let width = max(Int(ceil(ratio.width * multiplier)), 1)
        let height = max(Int(ceil(ratio.height * multiplier)), 1)
        return (width, height)
    }

    private func loadContent(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        quoteOverride: Quote?,
        minimumLoaderDuration: TimeInterval?,
        cacheIdentity: String?
    ) async throws -> FeedPageContent {
        let taskKey = cacheKey(
            category: category,
            aspectRatio: aspectRatio,
            quoteOverride: quoteOverride,
            cacheIdentity: cacheIdentity
        )

        if let inFlight = inFlightTasks[taskKey] {
            return try await inFlight.value
        }

        let task = Task<FeedPageContent, Error> {
            let start = Date()
            guard let depth = depthFromCacheIdentity(cacheIdentity) else {
                throw FeedCatalogueError.unavailable
            }

            let page = try await prefetchFeedPageUseCase.execute(
                category: category,
                depth: depth,
                quoteOverride: quoteOverride
            )
            let image = try await imageLoader.load(url: page.imageURL)
            let content = FeedPageContent(
                quote: page.quote,
                image: image,
                imageURL: page.imageURL,
                imageSource: page.imageSource,
                seed: page.seed,
                imageCategoryTitle: page.imageCategoryTitle
            )

            if let minimumLoaderDuration {
                let elapsed = Date().timeIntervalSince(start)
                if elapsed < minimumLoaderDuration {
                    try await Task.sleep(nanoseconds: UInt64((minimumLoaderDuration - elapsed) * 1_000_000_000))
                }
            }
            return content
        }

        inFlightTasks[taskKey] = task
        defer { inFlightTasks[taskKey] = nil }
        return try await task.value
    }

    private func cacheKey(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        quoteOverride: Quote?,
        cacheIdentity: String?
    ) -> String {
        let overridePart = quoteOverride?.id ?? quoteOverride?.text ?? ""
        let identityPart = cacheIdentity ?? "default"
        return "\(identityPart)|\(category?.rawValue ?? "random")|\(aspectRatio.rawValue)|\(overridePart)"
    }

    private func depthFromCacheIdentity(_ cacheIdentity: String?) -> Int? {
        guard let cacheIdentity else { return nil }
        guard let depthPart = cacheIdentity.split(separator: "|").last else { return nil }
        guard depthPart.first == "d" else { return nil }
        return Int(depthPart.dropFirst())
    }

    private func userFacingMessage(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedMessage()
        }

        if let local = error as? LocalizedError, let description = local.errorDescription {
            return description
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return String(\CommonStrings.errorsNetworkUnreachable)
            case .timedOut:
                return String(\MotivationStrings.errorTimeout)
            default:
                break
            }
        }

        return String(\MotivationStrings.errorRefresh)
    }
}
