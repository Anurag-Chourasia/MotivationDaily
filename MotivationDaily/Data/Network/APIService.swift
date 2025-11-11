import Foundation

final class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let trustDelegate: APIServiceTrustDelegate?

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
            self.trustDelegate = nil
            return
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 8 * 1024 * 1024,
            diskCapacity: 40 * 1024 * 1024,
            diskPath: "motivationdaily-urlcache"
        )
        let delegate = APIServiceTrustDelegate(allowedHosts: ["api.quotable.io"])
        self.trustDelegate = delegate
        self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }

    func getData(_ url: URL, cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = cachePolicy
        request.timeoutInterval = 25

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkMessage("Invalid response.")
        }
        guard (200...299).contains(http.statusCode) else {
            throw AppError.network(status: http.statusCode)
        }
        guard !data.isEmpty else {
            throw AppError.emptyResponse
        }
        return data
    }

    func getDecodable<T: Decodable>(
        _ url: URL,
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let data = try await getData(url, cachePolicy: cachePolicy)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decoding("Failed to decode response: \(error.localizedDescription)")
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

private final class APIServiceTrustDelegate: NSObject, URLSessionDelegate {
    private let allowedHosts: Set<String>

    init(allowedHosts: Set<String>) {
        self.allowedHosts = allowedHosts
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              allowedHosts.contains(challenge.protectionSpace.host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
