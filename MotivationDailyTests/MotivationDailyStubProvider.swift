import Foundation
@testable import MotivationDaily

/// Provides structured stub data loaded from the AppStubData submodule for Motivation Daily.
struct MotivationDailyStubProvider {

    enum Scenario: String, CaseIterable { case positive, empty, negative }

    private final class BundleMarker {}

    private static func data(endpoint: String, scenario: Scenario) throws -> Data {
        let name = "motivationdaily-\(endpoint)-\(scenario.rawValue)"
        guard let url = Bundle(for: BundleMarker.self).url(forResource: name, withExtension: "json", subdirectory: "Resources") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }

    static func loadQuotes(scenario: Scenario = .positive) throws -> [QuotableQuoteDTO] {
        let data = try data(endpoint: "quotes", scenario: scenario)
        return try JSONDecoder().decode([QuotableQuoteDTO].self, from: data)
    }

    static func loadAuthors(scenario: Scenario = .positive) throws -> [[String: Any]] {
        let data = try data(endpoint: "authors", scenario: scenario)
        return try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
    }

    static func loadWallpapers(scenario: Scenario = .positive) throws -> [PicsumImageDTO] {
        let data = try data(endpoint: "wallpapers", scenario: scenario)
        return try JSONDecoder().decode([PicsumImageDTO].self, from: data)
    }
}
