import Foundation
import UIKit

actor ImageLoader {
    nonisolated static let shared = ImageLoader()

    private let session: URLSession
    private let cache: LightImageCache
    private let retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    private let maxRetryAttempts = 1
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    init(
        session: URLSession = ImageLoader.makeDefaultSession(),
        cache: LightImageCache = .shared
    ) {
        self.session = session
        self.cache = cache
    }

    func load(url: URL) async throws -> UIImage {
        if let cached = cache.image(for: url) {
            return cached
        }

        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }

        let retryableStatusCodes = self.retryableStatusCodes
        let maxRetryAttempts = self.maxRetryAttempts
        let task = Task<UIImage, Error> { [session, cache] in
            var attempt = 0
            var lastError: Error?

            while attempt <= maxRetryAttempts {
                do {
                    let image = try await Self.loadOnce(url: url, session: session)
                    cache.insert(image, for: url)
                    return image
                } catch {
                    if Task.isCancelled { throw CancellationError() }
                    lastError = error
                    if attempt == maxRetryAttempts || !Self.shouldRetry(error, retryableStatusCodes: retryableStatusCodes) {
                        break
                    }
                    let delay = UInt64((0.25 * pow(2.0, Double(attempt))) * 1_000_000_000)
                    try await Task.sleep(nanoseconds: delay)
                    attempt += 1
                }
            }

            throw lastError ?? AppError.networkMessage("Image load failed.")
        }

        inFlightTasks[url] = task
        defer { inFlightTasks[url] = nil }
        return try await task.value
    }

    func cachedImage(for url: URL) -> UIImage? {
        if url.isFileURL {
            return UIImage(contentsOfFile: url.path)
        }

        if let inMemory = cache.image(for: url) {
            return inMemory
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataDontLoad
        guard
            let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request),
            !cachedResponse.data.isEmpty,
            let decoded = UIImage(data: cachedResponse.data)
        else {
            return nil
        }

        cache.insert(decoded, for: url)
        return decoded
    }

    private static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(
            memoryCapacity: 80 * 1024 * 1024,
            diskCapacity: 300 * 1024 * 1024,
            diskPath: "motivationdaily.images.urlcache"
        )
        configuration.timeoutIntervalForRequest = 25
        configuration.timeoutIntervalForResource = 45
        return URLSession(configuration: configuration)
    }

    private static func loadOnce(url: URL, session: URLSession) async throws -> UIImage {
        if url.isFileURL {
            do {
                let data = try Data(contentsOf: url)
                if data.isEmpty {
                    throw AppError.emptyResponse
                }
                return try await Task.detached(priority: .userInitiated) { () -> UIImage in
                    guard let decoded = UIImage(data: data) else {
                        throw AppError.decoding("Failed to decode image data.")
                    }
                    if let prepared = decoded.preparingForDisplay() {
                        return prepared
                    }
                    return decoded
                }.value
            } catch {
                if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
                    return Self.makePlaceholderImage()
                }
                throw error
            }
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 25

        let (data, response) = try await session.data(for: request)
        if Task.isCancelled { throw CancellationError() }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AppError.network(status: http.statusCode)
        }

        if data.isEmpty {
            throw AppError.emptyResponse
        }

        return try await Task.detached(priority: .userInitiated) { () -> UIImage in
            guard let decoded = UIImage(data: data) else {
                throw AppError.decoding("Failed to decode image data.")
            }
            if let prepared = decoded.preparingForDisplay() {
                return prepared
            }
            return decoded
        }.value
    }

    private static func shouldRetry(
        _ error: Error,
        retryableStatusCodes: Set<Int>
    ) -> Bool {
        if let appError = error as? AppError, case .network(let status) = appError {
            return retryableStatusCodes.contains(status)
        }

        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut,
             .networkConnectionLost,
             .notConnectedToInternet,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func makePlaceholderImage() -> UIImage {
        let size = CGSize(width: 900, height: 1600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let colors = [UIColor(red: 0.10, green: 0.12, blue: 0.22, alpha: 1).cgColor,
                          UIColor(red: 0.18, green: 0.30, blue: 0.42, alpha: 1).cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors as CFArray,
                                            locations: [0, 1]) else {
                UIColor.black.setFill()
                context.cgContext.fill(rect)
                return
            }
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
    }
}
