import SwiftUI
import UIKit
import Combine

@MainActor
final class FeedPageViewModel: ObservableObject {
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

    let prefetchFeedPageUseCase: PrefetchFeedPageUseCase
    let imageLoader: any ImageLoading
    var inFlightTasks: [String: Task<FeedPageContent, Error>] = [:]

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
}
