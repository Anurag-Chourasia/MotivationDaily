import Foundation

struct Category: Codable, Hashable {
    let key: CategoryKey
    let displayName: String
    let quoteCount: Int?

    init(key: CategoryKey, displayName: String, quoteCount: Int? = nil) {
        self.key = key
        self.displayName = displayName
        self.quoteCount = quoteCount
    }
}
