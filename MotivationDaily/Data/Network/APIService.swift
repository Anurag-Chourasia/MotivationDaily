import Foundation
import CommonNetworking

final class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let trustDelegate: APIServiceTrustDelegate?
    private let client: CommonNetworking.HTTPClient

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
            self.trustDelegate = nil
            #if DEBUG
            let logging = UserDefaults.standard.object(forKey: "developer.httpLogs") as? Bool
                ?? (ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1")
            self.client = CommonNetworking.HTTPClient(session: session, logger: logging ? .console : nil)
            #else
            self.client = CommonNetworking.HTTPClient(session: session)
            #endif
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
        let createdSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        self.session = createdSession

        #if DEBUG
        let logging = UserDefaults.standard.object(forKey: "developer.httpLogs") as? Bool
            ?? (ProcessInfo.processInfo.environment["HTTP_LOGGING"] == "1")
        self.client = CommonNetworking.HTTPClient(session: createdSession, logger: logging ? .console : nil)
        #else
        self.client = CommonNetworking.HTTPClient(session: createdSession)
        #endif
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
