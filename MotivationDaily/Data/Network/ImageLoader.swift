import Foundation
import UIKit
import DesignTokensKit

protocol ImageLoading: Sendable {
    func load(url: URL) async throws -> UIImage
    func cachedImage(for url: URL) async -> UIImage?
}

actor ImageLoader: ImageLoading {
    nonisolated static let shared = ImageLoader()

    private let session: URLSession
    private let cache: LightImageCache
    private let retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    private let maxRetryAttempts = 1
    private let retrySleep: @Sendable (UInt64) async throws -> Void
    private struct PendingRequest {
        let id: UUID
        let task: Task<Void, Never>
        var waiters: [UUID: CheckedContinuation<UIImage, Error>]
    }
    private var inFlightTasks: [URL: PendingRequest] = [:]

    init(
        session: URLSession = ImageLoader.makeDefaultSession(),
        cache: LightImageCache = .shared,
        retrySleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) {
        self.session = session
        self.cache = cache
        self.retrySleep = retrySleep
    }

    func load(url: URL) async throws -> UIImage {
        try Task.checkCancellation()
        if let cached = cache.image(for: url) { return cached }
        let waiterID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                if inFlightTasks[url] != nil {
                    inFlightTasks[url]?.waiters[waiterID] = continuation
                    return
                }
                let requestID = UUID()
                let task = Task { [session, cache, retryableStatusCodes, maxRetryAttempts, retrySleep] in
                    let result: Result<UIImage, Error>
                    do {
                        let image = try await Self.loadWithRetry(
                            url: url, session: session,
                            retryableStatusCodes: retryableStatusCodes,
                            maxRetryAttempts: maxRetryAttempts, retrySleep: retrySleep)
                        try Task.checkCancellation()
                        result = .success(image)
                    } catch { result = .failure(error) }
                    complete(url: url, requestID: requestID, result: result, cache: cache)
                }
                inFlightTasks[url] = PendingRequest(id: requestID, task: task,
                                                   waiters: [waiterID: continuation])
            }
        } onCancel: {
            Task { await self.cancelWaiter(waiterID, url: url) }
        }
    }

    // Internal diagnostics also provide a deterministic synchronization point for cancellation tests.
    func pendingCallerCount(for url: URL) -> Int { inFlightTasks[url]?.waiters.count ?? 0 }

    private func cancelWaiter(_ waiterID: UUID, url: URL) {
        guard let waiter = inFlightTasks[url]?.waiters.removeValue(forKey: waiterID) else { return }
        waiter.resume(throwing: CancellationError())
        if inFlightTasks[url]?.waiters.isEmpty == true {
            let task = inFlightTasks.removeValue(forKey: url)?.task
            task?.cancel()
        }
    }

    private func complete(url: URL, requestID: UUID, result: Result<UIImage, Error>, cache: LightImageCache) {
        guard inFlightTasks[url]?.id == requestID,
              let pending = inFlightTasks.removeValue(forKey: url) else { return }
        if case let .success(image) = result { cache.insert(image, for: url) }
        for waiter in pending.waiters.values { waiter.resume(with: result) }
    }

    private static func loadWithRetry(url: URL, session: URLSession,
                                      retryableStatusCodes: Set<Int>, maxRetryAttempts: Int,
                                      retrySleep: @Sendable (UInt64) async throws -> Void) async throws -> UIImage {
        for attempt in 0...maxRetryAttempts {
            try Task.checkCancellation()
            do { return try await loadOnce(url: url, session: session) }
            catch {
                try Task.checkCancellation()
                guard attempt < maxRetryAttempts,
                      shouldRetry(error, retryableStatusCodes: retryableStatusCodes) else { throw error }
                let delay = UInt64((0.25 * pow(2.0, Double(attempt))) * 1_000_000_000)
                try await retrySleep(delay)
            }
        }
        throw AppError.networkMessage("Image load failed.")
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
            let colors = [PlaceholderColorToken.uiGradientStart.cgColor,
                          PlaceholderColorToken.uiGradientEnd.cgColor]
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
