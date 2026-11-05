import XCTest
import UIKit
@testable import MotivationDaily

@MainActor
final class ImageLoaderCancellationTests: XCTestCase {
    func testCancellingOneCallerPreservesSharedRequest() async throws {
        let harness = ImageRequestHarness()
        let (loader, session, url) = makeLoader(harness)
        defer { session.invalidateAndCancel() }
        let first = Task { try await loader.load(url: url) }
        let second = Task { try await loader.load(url: url) }
        await fulfillment(of: [harness.started], timeout: 5)
        await waitForCallers(2, loader: loader, url: url)
        first.cancel()
        await assertCancelled(first)
        XCTAssertFalse(harness.wasStopped)
        harness.succeed()
        let image = try await second.value
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertEqual(harness.startCount, 1)
    }

    func testCancellingAllCallersStopsTransportAndAllowsReplacement() async throws {
        let harness = ImageRequestHarness()
        let (loader, session, url) = makeLoader(harness)
        defer { session.invalidateAndCancel() }
        let first = Task { try await loader.load(url: url) }
        await fulfillment(of: [harness.started], timeout: 5)
        first.cancel()
        await assertCancelled(first)
        await fulfillment(of: [harness.stopped], timeout: 5)
        let callerCount = await loader.pendingCallerCount(for: url)
        XCTAssertEqual(callerCount, 0)
        let replacement = Task { try await loader.load(url: url) }
        await fulfillment(of: [harness.restarted], timeout: 5)
        harness.succeed()
        _ = try await replacement.value
        XCTAssertEqual(harness.startCount, 2)
    }

    func testCancellingDuringBackoffPreventsRetry() async {
        let harness = ImageRequestHarness()
        ImageCancellationProtocol.install(harness)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ImageCancellationProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let backoff = XCTestExpectation(description: "retry delay entered")
        let loader = ImageLoader(session: session, retrySleep: { _ in
            backoff.fulfill()
            try await Task.sleep(nanoseconds: UInt64.max / 2)
        })
        let task = Task { try await loader.load(url: URL(string: "https://images.example/retry-\(UUID())")!) }
        await fulfillment(of: [harness.started], timeout: 5)
        harness.succeed(status: 503)
        await fulfillment(of: [backoff], timeout: 5)
        task.cancel()
        await assertCancelled(task)
        XCTAssertEqual(harness.startCount, 1)
    }

    func testAlreadyCancelledCallerDoesNotStartTransport() async {
        let harness = ImageRequestHarness()
        let (loader, session, url) = makeLoader(harness)
        defer { session.invalidateAndCancel() }
        let task = Task { try await loader.load(url: url) }
        task.cancel()
        await assertCancelled(task)
        XCTAssertEqual(harness.startCount, 0)
    }

    private func waitForCallers(_ count: Int, loader: ImageLoader, url: URL) async {
        for _ in 0..<10_000 {
            if await loader.pendingCallerCount(for: url) == count { return }
            await Task.yield()
        }
        XCTFail("Callers did not attach to the shared request")
    }

    private func assertCancelled(_ task: Task<UIImage, Error>) async {
        do { _ = try await task.value; XCTFail("Expected cancellation") }
        catch is CancellationError { }
        catch { XCTFail("Unexpected error: \(error)") }
    }

    private func makeLoader(_ harness: ImageRequestHarness) -> (ImageLoader, URLSession, URL) {
        ImageCancellationProtocol.install(harness)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ImageCancellationProtocol.self]
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        return (ImageLoader(session: session), session, URL(string: "https://images.example/\(UUID()).png")!)
    }
}

private final class ImageRequestHarness: @unchecked Sendable {
    let started = XCTestExpectation(description: "request started")
    let restarted = XCTestExpectation(description: "replacement started")
    let stopped = XCTestExpectation(description: "request cancelled")
    private let lock = NSLock()
    private var request: ImageCancellationProtocol?
    private var starts = 0
    private var stops = 0
    var startCount: Int { lock.withLock { starts } }
    var wasStopped: Bool { lock.withLock { stops > 0 } }
    func start(_ request: ImageCancellationProtocol) {
        let count = lock.withLock { self.request = request; starts += 1; return starts }
        if count == 1 { started.fulfill() } else { restarted.fulfill() }
    }
    func stop() { lock.withLock { stops += 1 }; stopped.fulfill() }
    func succeed(status: Int = 200) {
        guard let request = lock.withLock({ request }) else { return }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let data = renderer.pngData { _ in UIColor.red.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1)) }
        let response = HTTPURLResponse(url: request.request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        request.client?.urlProtocol(request, didReceive: response, cacheStoragePolicy: .notAllowed)
        request.client?.urlProtocol(request, didLoad: data)
        request.client?.urlProtocolDidFinishLoading(request)
    }
}

private final class ImageCancellationProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var harness: ImageRequestHarness?
    private var owner: ImageRequestHarness?
    static func install(_ value: ImageRequestHarness) { lock.withLock { harness = value } }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { owner = Self.lock.withLock { Self.harness }; owner?.start(self) }
    override func stopLoading() { owner?.stop() }
}
