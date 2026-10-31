import Foundation

struct CategoryKey: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String

    nonisolated init(rawValue: String) {
        self.rawValue = rawValue
    }
}
