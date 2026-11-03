//
//  PerformanceTests.swift
//  MotivationDailyTests
//
//  Created by Anurag Chourasia on 03/11/26.
//

import XCTest
import UIKit
@testable import MotivationDaily

final class PerformanceTests: XCTestCase {

    func testQuoteDiskCacheBatchThroughput() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = QuoteDiskCache(directory: tempDir)

        let quotes = (0..<100).map { index in
            Quote(
                id: "perf-quote-\(index)",
                text: "Inspirational message \(index) for performance benchmarking.",
                author: "Author \(index)",
                source: .quotable,
                categoryKey: CategoryKey(rawValue: "wisdom")
            )
        }

        measure {
            cache.save(quotes)
            let loaded = cache.load()
            XCTAssertEqual(loaded.count, 100)
        }

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testLightImageCacheThroughput() {
        let cache = LightImageCache.shared
        cache.removeAll()

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50))
        let image = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 50, height: 50))
        }

        let urls = (0..<80).compactMap { URL(string: "https://example.com/images/\($0).jpg") }

        measure {
            for url in urls {
                cache.insert(image, for: url)
            }
            for url in urls {
                let fetched = cache.image(for: url)
                XCTAssertNotNil(fetched)
            }
        }

        cache.removeAll()
    }

    func testQuoteDecodingThroughput() {
        let sampleQuote = """
        {"_id": "item-id", "content": "The only way to do great work is to love what you do.", "author": "Steve Jobs", "tags": ["inspirational"]}
        """
        let list = (0..<200).map { _ in sampleQuote }.joined(separator: ",")
        let jsonString = "{\"count\": 200, \"totalCount\": 200, \"page\": 1, \"totalPages\": 1, \"results\": [\(list)]}"
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to encode test JSON")
            return
        }

        let decoder = JSONDecoder()
        measure {
            let response = try? decoder.decode(QuotableQuotesPageDTO.self, from: jsonData)
            XCTAssertEqual(response?.results.count, 200)
        }
    }
}
