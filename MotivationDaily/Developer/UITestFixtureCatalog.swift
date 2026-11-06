#if DEBUG
import Foundation
import UIKit

/// The host decodes resources; fixture values remain owned by AppStubData.
nonisolated struct UITestFixtureCatalog: Decodable, Sendable {
    struct Favorite: Decodable, Sendable {
        let id: String
        let text: String
    }
    struct Category: Decodable, Sendable {
        let key: String
        let name: String
        let quoteCount: Int
    }
    let gradientPalettes: [[[Double]]]
    let author: String
    let favorite: Favorite
    let categories: [Category]
    let randomQuoteCount: Int

    static let current: UITestFixtureCatalog = {
        do { return try load() }
        catch { preconditionFailure("Invalid or missing Debug fixture catalog: \(error)") }
    }()

    static func load() throws -> UITestFixtureCatalog {
        guard let file = Bundle.main.url(forResource: "motivationdaily-ui-fixtures", withExtension: "json",
                                         subdirectory: "DeveloperFixtures") else { throw CocoaError(.fileNoSuchFile) }
        return try decode(Data(contentsOf: file))
    }

    static func decode(_ data: Data) throws -> UITestFixtureCatalog {
        let value = try JSONDecoder().decode(Self.self, from: data)
        guard !value.gradientPalettes.isEmpty,
              value.gradientPalettes.allSatisfy({ palette in
                  palette.count == 2 && palette.allSatisfy { rgba in
                      rgba.count == 4 && rgba.allSatisfy { $0.isFinite && (0...1).contains($0) }
                  }
              }), value.randomQuoteCount > 0,
              value.categories.allSatisfy({ !$0.key.isEmpty && $0.quoteCount > 0 }),
              Set(value.categories.map(\.key)).count == value.categories.count else { throw CocoaError(.coderReadCorrupt) }
        return value
    }

    func palette(for seed: Int) -> [UIColor] {
        gradientPalettes[Int(seed.magnitude % UInt(gradientPalettes.count))].map {
            UIColor(red: CGFloat($0[0]), green: CGFloat($0[1]), blue: CGFloat($0[2]), alpha: CGFloat($0[3]))
        }
    }
}
#endif
