import Foundation

final class AdviceSlipClient {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func fetchRandomAdvice() async throws -> AdviceSlipDTO {
        let url = try apiService.makeURL(
            base: "https://api.adviceslip.com",
            path: "/advice"
        )
        let response: AdviceSlipResponseDTO = try await apiService.getDecodable(
            url,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        return response.slip
    }
}
