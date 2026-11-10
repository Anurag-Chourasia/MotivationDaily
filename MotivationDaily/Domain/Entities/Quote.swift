import Foundation

struct Quote: Codable, Identifiable, Equatable, Sendable {
    let id: String?
    let text: String
    let author: String?
    let source: QuoteSource
    let categoryKey: CategoryKey?
}
