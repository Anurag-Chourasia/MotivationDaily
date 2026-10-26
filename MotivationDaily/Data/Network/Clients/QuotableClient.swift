import Foundation

import Foundation

private struct DummyJSONQuotesResponseDTO: Decodable {
    struct Item: Decodable {
        let id: Int
        let quote: String
        let author: String
    }
    let quotes: [Item]
    let total: Int
}

final class QuotableClient {
    private let apiService: APIService
    private let decoder: JSONDecoder
    private var cachedQuotes: [DummyJSONQuotesResponseDTO.Item] = []
    private var fetchTask: Task<[DummyJSONQuotesResponseDTO.Item], Error>?

    private let categoryKeywords: [String: [String]] = [
        "happiness": ["happy", "happiness", "joy", "smile", "laugh", "pleasure", "peace", "glad", "cheer", "bliss", "delight", "heart", "love", "kind"],
        "inspirational": ["inspire", "inspiration", "dream", "courage", "brave", "believe", "passion", "strength", "strive", "possible", "great", "future", "hope", "power"],
        "inspiration": ["inspire", "inspiration", "dream", "courage", "brave", "believe", "passion", "strength", "strive", "possible", "great", "future", "hope", "power"],
        "life": ["life", "live", "living", "world", "moment", "journey", "day", "time", "experience", "alive", "beauty"],
        "success": ["success", "succeed", "successful", "work", "goal", "failure", "fail", "effort", "achieve", "win", "action", "perseverance", "result", "discipline"],
        "wisdom": ["wisdom", "wise", "truth", "know", "knowledge", "mind", "think", "thought", "learn", "understand", "reason", "philosophy", "silence"]
    ]

    init(apiService: APIService, decoder: JSONDecoder = JSONDecoder()) {
        self.apiService = apiService
        self.decoder = decoder
    }

    private func allQuotes() async throws -> [DummyJSONQuotesResponseDTO.Item] {
        if !cachedQuotes.isEmpty {
            return cachedQuotes
        }
        if let existing = fetchTask {
            return try await existing.value
        }
        let task = Task<[DummyJSONQuotesResponseDTO.Item], Error> {
            let url = try apiService.makeURL(
                base: "https://dummyjson.com",
                path: "/quotes",
                queryItems: [URLQueryItem(name: "limit", value: "0")]
            )
            let response: DummyJSONQuotesResponseDTO = try await apiService.getDecodable(
                url,
                cachePolicy: .returnCacheDataElseLoad,
                decoder: decoder
            )
            return response.quotes
        }
        fetchTask = task
        defer { fetchTask = nil }
        let quotes = try await task.value
        cachedQuotes = quotes
        return quotes
    }

    private func quotes(for tag: String) async throws -> [QuotableQuoteDTO] {
        let items = try await allQuotes()
        let normalizedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let keywords = categoryKeywords[normalizedTag] ?? [normalizedTag]
        let filtered = items.filter { item in
            let lower = item.quote.lowercased()
            return keywords.contains { lower.contains($0) }
        }
        let results = filtered.isEmpty ? items : filtered
        return results.shuffled().map {
            QuotableQuoteDTO(
                _id: "dj-\($0.id)",
                content: $0.quote,
                author: $0.author
            )
        }
    }

    func fetchRandomQuote(tags: String) async throws -> QuotableQuoteDTO {
        let list = try await quotes(for: tags)
        guard let random = list.randomElement() else {
            throw AppError.emptyResponse
        }
        return random
    }

    func fetchTags() async throws -> [QuotableTagDTO] {
        let items = try await allQuotes()
        let configs: [(slug: String, name: String)] = [
            ("happiness", "Happiness"),
            ("inspirational", "Inspiration"),
            ("life", "Life"),
            ("success", "Success"),
            ("wisdom", "Wisdom")
        ]
        return configs.map { config in
            let keywords = categoryKeywords[config.slug] ?? []
            let count = items.filter { item in
                let lower = item.quote.lowercased()
                return keywords.contains { lower.contains($0) }
            }.count
            return QuotableTagDTO(
                _id: config.slug,
                name: config.name,
                slug: config.slug,
                quoteCount: count
            )
        }
    }

    func fetchQuotes(tags: String, page: Int, limit: Int) async throws -> QuotableQuotesPageDTO {
        let list = try await quotes(for: tags)
        let totalCount = list.count
        let pageSize = max(limit, 1)
        let totalPages = max(Int(ceil(Double(totalCount) / Double(pageSize))), 1)
        let startIndex = max(page - 1, 0) * pageSize
        let pageResults: [QuotableQuoteDTO]
        if startIndex < totalCount {
            let endIndex = min(startIndex + pageSize, totalCount)
            pageResults = Array(list[startIndex..<endIndex])
        } else {
            pageResults = []
        }
        return QuotableQuotesPageDTO(
            count: pageResults.count,
            totalCount: totalCount,
            page: page,
            totalPages: totalPages,
            lastItemIndex: startIndex + pageResults.count,
            results: pageResults
        )
    }
}
