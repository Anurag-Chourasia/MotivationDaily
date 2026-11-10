#if DEBUG
import Foundation

final class PreviewQuoteRepository: QuoteRepository, Sendable {
    private let fixture: UITestFixtureCatalog

    init(fixture: UITestFixtureCatalog = .current) {
        self.fixture = fixture
    }

    func fetchRandom() async throws -> Quote {
        Quote(
            id: fixture.favorite.id,
            text: fixture.favorite.text,
            author: fixture.author,
            source: .adviceSlip,
            categoryKey: nil
        )
    }

    func fetchByCategory(_ key: CategoryKey) async throws -> Quote {
        let matchingCategory = fixture.categories.first { $0.key == key.rawValue }
        let categoryName = matchingCategory?.name ?? key.rawValue.capitalized
        return Quote(
            id: "preview-\(key.rawValue)",
            text: "\(categoryName) quote for daily motivation.",
            author: fixture.author,
            source: .quotable,
            categoryKey: key
        )
    }

    func fetchCategories() async throws -> [Category] {
        fixture.categories.compactMap { (cat: UITestFixtureCatalog.Category) -> Category? in
            let key = CategoryKey(rawValue: cat.key)
            return Category(key: key, displayName: cat.name, quoteCount: cat.quoteCount)
        }
    }
}
#endif
