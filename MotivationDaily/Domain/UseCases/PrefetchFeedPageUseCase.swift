import Foundation

struct PrefetchFeedPageUseCase: Sendable {
    private let repository: any FeedCatalogueRepository

    init(repository: any FeedCatalogueRepository) {
        self.repository = repository
    }

    func execute(
        category: CategoryKey?,
        depth: Int,
        quoteOverride: Quote? = nil
    ) async throws -> FeedCataloguePage {
        try await repository.page(category: category, depth: depth, quoteOverride: quoteOverride)
    }

    func warmup() async {
        await repository.warmup()
    }

    func categories(fallback: [Category]) async -> [Category] {
        await repository.categories(fallback: fallback)
    }

    func randomQuoteCount() async -> Int {
        await repository.randomQuoteCount()
    }
}
