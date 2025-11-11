import Foundation

struct FetchCategoriesUseCase {
    private let repository: any QuoteRepository

    init(repository: any QuoteRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Category] {
        try await repository.fetchCategories()
    }
}
