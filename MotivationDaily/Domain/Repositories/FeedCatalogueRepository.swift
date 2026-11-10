import Foundation

protocol FeedCatalogueRepository: Sendable {
    func page(category: CategoryKey?, depth: Int, quoteOverride: Quote?) async throws -> FeedCataloguePage
    func warmup() async
    func categories(fallback: [Category]) async -> [Category]
    func randomQuoteCount() async -> Int
}
