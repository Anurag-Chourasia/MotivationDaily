import Foundation

protocol QuoteRepository {
    func fetchRandom() async throws -> Quote
    func fetchByCategory(_ key: CategoryKey) async throws -> Quote
    func fetchCategories() async throws -> [Category]
}
