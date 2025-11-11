import Foundation

final class ZenQuotesClient {
    private let apiService: APIService
    private let decoder: JSONDecoder

    init(apiService: APIService, decoder: JSONDecoder = JSONDecoder()) {
        self.apiService = apiService
        self.decoder = decoder
    }

    func fetchRandomQuote() async throws -> ZenQuoteDTO {
        let url = try apiService.makeURL(base: "https://zenquotes.io", path: "/api/random")
        let data = try await apiService.getData(url, cachePolicy: .reloadIgnoringLocalCacheData)

        if let apiError = try? decoder.decode(ZenErrorDTO.self, from: data),
           let message = apiError.error,
           !message.isEmpty {
            throw AppError.networkMessage(message)
        }

        let quotes = try decoder.decode([ZenQuoteDTO].self, from: data)
        guard let first = quotes.first else {
            throw AppError.emptyResponse
        }
        return first
    }

    func fetchQuotes() async throws -> [ZenQuoteDTO] {
        let url = try apiService.makeURL(base: "https://zenquotes.io", path: "/api/quotes")
        let data = try await apiService.getData(url, cachePolicy: .reloadIgnoringLocalCacheData)

        if let apiError = try? decoder.decode(ZenErrorDTO.self, from: data),
           let message = apiError.error,
           !message.isEmpty {
            throw AppError.networkMessage(message)
        }

        let quotes = try decoder.decode([ZenQuoteDTO].self, from: data)
        guard !quotes.isEmpty else {
            throw AppError.emptyResponse
        }
        return quotes
    }
}
