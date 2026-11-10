import Foundation

protocol QuoteRepository: Sendable {
    func fetchRandom() async throws -> Quote
    func fetchByCategory(_ key: CategoryKey) async throws -> Quote
    func fetchCategories() async throws -> [Category]
}
