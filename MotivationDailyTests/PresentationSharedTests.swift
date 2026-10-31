import XCTest
import SwiftUI
import UIKit
@testable import MotivationDaily

final class PresentationSharedTests: XCTestCase {

    // MARK: - QuoteCardLayout Tests

    func testQuoteCardLayout() {
        let compactRect = CGRect(x: 0, y: 0, width: 300, height: 350)
        let compactLayout = QuoteCardLayout.style(for: compactRect)
        XCTAssertTrue(compactLayout.isCompact)
        XCTAssertGreaterThan(compactLayout.width, 0)

        let normalRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let normalLayout = QuoteCardLayout.style(for: normalRect)
        XCTAssertFalse(normalLayout.isCompact)
        XCTAssertGreaterThan(normalLayout.width, 0)

        let sizeLayout = QuoteCardLayout.style(for: CGSize(width: 320, height: 400))
        XCTAssertTrue(sizeLayout.isCompact)
    }

    // MARK: - LightImageCache Tests

    func testLightImageCache() {
        let cache = LightImageCache.shared
        let url = URL(string: "https://example.com/cached.jpg")!

        XCTAssertNil(cache.image(for: url))

        let image = UIImage()
        cache.insert(image, for: url)
        XCTAssertNotNil(cache.image(for: url))

        cache.removeAll()
        XCTAssertNil(cache.image(for: url))
    }

    // MARK: - NetworkMonitor Tests

    @MainActor
    func testNetworkMonitor() {
        let monitor = NetworkMonitor()
        XCTAssertTrue(monitor.isConnected)
    }

    // MARK: - ImageLoader Tests

    func testImageLoader() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("image_loader_test_\(UUID().uuidString).jpg")

        // Create a small test JPEG
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let img = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        let data = img.jpegData(compressionQuality: 0.9)!
        try data.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let loader = ImageLoader.shared
        let loadedImage = try await loader.load(url: fileURL)
        XCTAssertNotNil(loadedImage)

        let cached = await loader.cachedImage(for: fileURL)
        XCTAssertNotNil(cached)

        // Custom session loader with MockURLProtocol
        let mockSession = MockURLProtocol.makeMockSession()
        let customLoader = ImageLoader(session: mockSession, cache: .shared)

        let mockURL = URL(string: "https://example.com/network_image.jpg")!

        // 1. Success network load
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        let remoteImg = try await customLoader.load(url: mockURL)
        XCTAssertNotNil(remoteImg)

        // Cache hit
        let inMemory = await customLoader.cachedImage(for: mockURL)
        XCTAssertNotNil(inMemory)

        // 2. 500 server error (retries)
        let failURL = URL(string: "https://example.com/500_fail.jpg")!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        do {
            _ = try await customLoader.load(url: failURL)
            XCTFail("Expected failure")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 3. 404 error (no retry)
        let notFoundURL = URL(string: "https://example.com/404.jpg")!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        do {
            _ = try await customLoader.load(url: notFoundURL)
            XCTFail("Expected failure")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 4. Empty data on 200
        let emptyURL = URL(string: "https://example.com/empty.jpg")!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        do {
            _ = try await customLoader.load(url: emptyURL)
            XCTFail("Expected failure")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 5. Corrupt data on 200
        let corruptURL = URL(string: "https://example.com/corrupt.jpg")!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data([0xDE, 0xAD, 0xBE, 0xEF]))
        }
        do {
            _ = try await customLoader.load(url: corruptURL)
            XCTFail("Expected failure")
        } catch {
            XCTAssertTrue(error is AppError)
        }

        // 6. File URL with empty data
        let emptyFileURL = tempDir.appendingPathComponent("empty_\(UUID().uuidString).jpg")
        try Data().write(to: emptyFileURL)
        defer { try? FileManager.default.removeItem(at: emptyFileURL) }
        do {
            _ = try await customLoader.load(url: emptyFileURL)
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    // MARK: - FavoriteQuote Resolved Local Image URL Tests

    func testFavoriteQuoteResolvedLocalImageURL() throws {
        // nil localImagePath
        let favNil = FavoriteQuote(
            id: "f1", text: "T", author: "A", source: .zenQuotes, categoryKey: nil,
            imageURL: nil, localImagePath: nil, ratioRawValue: nil, imageWidth: nil, imageHeight: nil
        )
        XCTAssertNil(favNil.resolvedLocalImageURL)

        // empty localImagePath
        let favEmpty = FavoriteQuote(
            id: "f2", text: "T", author: "A", source: .zenQuotes, categoryKey: nil,
            imageURL: nil, localImagePath: "", ratioRawValue: nil, imageWidth: nil, imageHeight: nil
        )
        XCTAssertNil(favEmpty.resolvedLocalImageURL)

        // non-existent path
        let favMissing = FavoriteQuote(
            id: "f3", text: "T", author: "A", source: .zenQuotes, categoryKey: nil,
            imageURL: nil, localImagePath: "nonexistent_file_xyz.jpg", ratioRawValue: nil, imageWidth: nil, imageHeight: nil
        )
        XCTAssertNil(favMissing.resolvedLocalImageURL)

        // file in FavoriteImages folder
        let fileManager = FileManager.default
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let favDir = baseDirectory.appendingPathComponent("FavoriteImages", isDirectory: true)
        try? fileManager.createDirectory(at: favDir, withIntermediateDirectories: true)
        let testFile = favDir.appendingPathComponent("test_fav_image.jpg")
        try Data([0x01, 0x02, 0x03]).write(to: testFile)

        let favFound = FavoriteQuote(
            id: "f4", text: "T", author: "A", source: .zenQuotes, categoryKey: nil,
            imageURL: nil, localImagePath: "test_fav_image.jpg", ratioRawValue: nil, imageWidth: nil, imageHeight: nil
        )
        XCTAssertNotNil(favFound.resolvedLocalImageURL)

        // absolute path pointing to testFile
        let favAbs = FavoriteQuote(
            id: "f5", text: "T", author: "A", source: .zenQuotes, categoryKey: nil,
            imageURL: nil, localImagePath: testFile.path, ratioRawValue: nil, imageWidth: nil, imageHeight: nil
        )
        XCTAssertNotNil(favAbs.resolvedLocalImageURL)
    }

    // MARK: - QuoteImageComposer Tests

    @MainActor
    func testQuoteImageComposer() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 300))
        let baseImage = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
        }

        let composed = QuoteImageComposer.compose(
            image: baseImage,
            quoteText: "Stay hungry, stay foolish.",
            author: "Steve Jobs",
            layoutSize: CGSize(width: 200, height: 300)
        )
        XCTAssertGreaterThan(composed.size.width, 0)
        XCTAssertGreaterThan(composed.size.height, 0)

        let composed2 = QuoteImageComposer.composeQuoteImage(
            source: baseImage,
            quoteText: "Keep moving.",
            author: "Martin Luther King",
            layoutSize: nil
        )
        XCTAssertGreaterThan(composed2.size.width, 0)

        let quoteOnly = QuoteImageComposer.composeQuoteOnly(
            quoteText: "Do what you can.",
            author: "Theodore Roosevelt",
            size: CGSize(width: 200, height: 200),
            scale: 1.0
        )
        XCTAssertEqual(quoteOnly.size.width, 200)
        XCTAssertEqual(quoteOnly.size.height, 200)

        let quoteOnly2 = QuoteImageComposer.composeQuoteOnlyImage(
            quoteText: "Never give up.",
            author: "Winston Churchill",
            size: CGSize(width: 150, height: 150)
        )
        XCTAssertEqual(quoteOnly2.size.width, 150)

        let renderContext = QuoteImageComposer.renderContext(for: baseImage)
        XCTAssertEqual(renderContext.canvasSize.width, 200)
    }

    // MARK: - ViewSnapshot Tests

    @MainActor
    func testViewSnapshot() {
        let view = Text("Hello Snapshot")
        let image = view.snapshot(size: CGSize(width: 100, height: 50), scale: 1.0)
        XCTAssertEqual(image.size.width, 100)
        XCTAssertEqual(image.size.height, 50)
    }

    // MARK: - ActivityShareSheet Tests

    @MainActor
    func testActivityShareSheet() {
        let sheet = ActivityShareSheet(activityItems: ["Sample Quote Text"])
        let host = UIHostingController(rootView: sheet)
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            XCTFail("A connected window scene is required")
            return
        }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        defer { window.isHidden = true; window.rootViewController = nil }
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        XCTAssertNotNil(host.view)
    }
}
