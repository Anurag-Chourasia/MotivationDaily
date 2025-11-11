import Foundation

struct Quote: Codable, Identifiable, Equatable {
    let id: String?
    let text: String
    let author: String?
    let source: QuoteSource
    let categoryKey: CategoryKey?
}
