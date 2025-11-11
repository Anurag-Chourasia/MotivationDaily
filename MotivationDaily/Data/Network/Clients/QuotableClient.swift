import Foundation

final class QuotableClient {
    private let apiService: APIService
    private let decoder: JSONDecoder

    init(apiService: APIService, decoder: JSONDecoder = JSONDecoder()) {
        self.apiService = apiService
        self.decoder = decoder
    }

    func fetchRandomQuote(tags: String) async throws -> QuotableQuoteDTO {
        let url = try apiService.makeURL(
            base: "https://api.quotable.io",
            path: "/quotes/random",
            queryItems: [URLQueryItem(name: "tags", value: tags)]
        )
        let data = try await apiService.getData(url, cachePolicy: .reloadIgnoringLocalCacheData)

        let quotes = try decoder.decode([QuotableQuoteDTO].self, from: data)
        guard let first = quotes.first else {
            throw AppError.emptyResponse
        }
        return first
    }

    func fetchTags() async throws -> [QuotableTagDTO] {
        let url = try apiService.makeURL(
            base: "https://api.quotable.io",
            path: "/tags"
        )
        return try await apiService.getDecodable(
            url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            decoder: decoder
        )
    }

    func fetchQuotes(tags: String, page: Int, limit: Int) async throws -> QuotableQuotesPageDTO {
        let url = try apiService.makeURL(
            base: "https://api.quotable.io",
            path: "/quotes",
            queryItems: [
                URLQueryItem(name: "tags", value: tags),
                URLQueryItem(name: "page", value: String(max(page, 1))),
                URLQueryItem(name: "limit", value: String(max(limit, 1)))
            ]
        )
        return try await apiService.getDecodable(
            url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            decoder: decoder
        )
    }
}
