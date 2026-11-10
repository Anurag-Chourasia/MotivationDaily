import Foundation
import CommonNetworkingKit

final class APIService: Sendable {
    static let shared = APIService()

    private let client: CommonNetworkingKit.HTTPClient

    init(session: URLSession? = nil) {
        let session = session ?? Self.makeSession()
        #if DEBUG
        let logging = UserDefaults.standard.object(forKey: "developer.httpLogs") as? Bool
            ?? (ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1")
        self.client = CommonNetworkingKit.HTTPClient(session: session, logger: logging ? .console : nil)
        #else
        self.client = CommonNetworkingKit.HTTPClient(session: session)
        #endif
    }

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 8 * 1024 * 1024,
            diskCapacity: 40 * 1024 * 1024,
            diskPath: "motivationdaily-urlcache"
        )
        return URLSession(configuration: config)
    }

    func getData(_ url: URL, cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = cachePolicy
        request.timeoutInterval = 25
        request.setValue("MotivationDaily/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let response = try await client.send(request)
            guard (200...299).contains(response.statusCode) else {
                throw AppError.network(status: response.statusCode)
            }
            guard !response.data.isEmpty else {
                throw AppError.emptyResponse
            }
            return response.data
        } catch let error as HTTPClientError {
            switch error {
            case .nonHTTPResponse:
                throw AppError.networkMessage("Invalid response.")
            case .unsuccessfulStatus(let http):
                throw AppError.network(status: http.statusCode)
            case .emptyBody:
                throw AppError.emptyResponse
            }
        } catch is CancellationError {
            throw URLError(.cancelled)
        }
    }

    func getDecodable<T: Decodable>(
        _ url: URL,
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let data = try await getData(url, cachePolicy: cachePolicy)
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw AppError.decoding("Failed to decode response: \(decodingError.localizedDescription)")
        }
    }

    func makeURL(base: String, path: String? = nil, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: base) else {
            throw AppError.invalidURL
        }
        if let path {
            components.path = components.path.appending(path)
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw AppError.invalidURL
        }
        return url
    }
}
