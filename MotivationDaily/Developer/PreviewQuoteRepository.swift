#if DEBUG
import Foundation

final class PreviewQuoteRepository: QuoteRepository, Sendable {
    private let fixture: UITestFixtureCatalog
    private let isEmpty: Bool

    init(fixture: UITestFixtureCatalog = .current, isEmpty: Bool = false) {
        self.fixture = fixture
        self.isEmpty = isEmpty
    }

    func fetchRandom() async throws -> Quote {
        if isEmpty {
            throw AppError.emptyResponse
        }
        return Quote(
            id: fixture.favorite.id,
            text: fixture.favorite.text,
            author: fixture.author,
            source: .adviceSlip,
            categoryKey: nil
        )
    }

    func fetchByCategory(_ key: CategoryKey) async throws -> Quote {
        if isEmpty {
            throw AppError.emptyResponse
        }
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
        if isEmpty {
            return []
        }
        return fixture.categories.compactMap { (cat: UITestFixtureCatalog.Category) -> Category? in
            let key = CategoryKey(rawValue: cat.key)
            return Category(key: key, displayName: cat.name, quoteCount: cat.quoteCount)
        }
    }
}
#endif
