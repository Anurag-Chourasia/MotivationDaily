import Foundation
import UIKit

extension FeedPageViewModel {
    func loadContent(
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
}
