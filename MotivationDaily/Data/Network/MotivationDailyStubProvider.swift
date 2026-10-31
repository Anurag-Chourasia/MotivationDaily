import Foundation
import AppStubData

/// Provides structured stub data loaded from the AppStubData submodule for Motivation Daily.
struct MotivationDailyStubProvider {

    static func loadQuotes(scenario: Fixtures.Scenario = .positive) throws -> [QuotableQuoteDTO] {
        let data = try Fixtures.data(for: .motivationDaily).endpoint(.quotes).scenario(scenario)
        return try JSONDecoder().decode([QuotableQuoteDTO].self, from: data)
    }

    static func loadAuthors(scenario: Fixtures.Scenario = .positive) throws -> [[String: Any]] {
        let data = try Fixtures.data(for: .motivationDaily).endpoint(.authors).scenario(scenario)
        return try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
    }

    static func loadWallpapers(scenario: Fixtures.Scenario = .positive) throws -> [PicsumImageDTO] {
        let data = try Fixtures.data(for: .motivationDaily).endpoint(.wallpapers).scenario(scenario)
        return try JSONDecoder().decode([PicsumImageDTO].self, from: data)
    }
}
