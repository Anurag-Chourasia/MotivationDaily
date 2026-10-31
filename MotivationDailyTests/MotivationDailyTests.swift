import XCTest
@testable import MotivationDaily

@MainActor
final class FeedIdentityTests: XCTestCase {
    func testCacheIdentitySeparatesCategoriesRatiosAndImageSizes() {
        let random = FeedLaneKey(category: nil, ratio: .fullScreen, imageSize: (300, 600))
        let same = FeedLaneKey(category: nil, ratio: .fullScreen, imageSize: (300, 600))
        let category = FeedLaneKey(category: CategoryKey(rawValue: "focus"), ratio: .fullScreen, imageSize: (300, 600))
        let ratio = FeedLaneKey(category: nil, ratio: .oneToOne, imageSize: (300, 300))
        let resolution = FeedLaneKey(category: nil, ratio: .fullScreen, imageSize: (600, 1200))
        XCTAssertEqual(random, same)
        XCTAssertEqual(Set([random, same, category, ratio, resolution]).count, 4)
        XCTAssertEqual(random.categoryRawValue, "random")
    }

    func testPageCacheKeepsDistinctDepthsWithinALane() {
        let lane = FeedLaneKey(category: nil, ratio: .fullScreen, imageSize: (300, 600))
        let first = FeedCoordinate(lane: lane, depth: 0)
        let next = FeedCoordinate(lane: lane, depth: 1)
        let cache = [first: "first page", next: "next page"]
        XCTAssertEqual(cache[FeedCoordinate(lane: lane, depth: 0)], "first page")
        XCTAssertEqual(cache[next], "next page")
        XCTAssertEqual(cache.count, 2)
    }
}
