import Foundation
import UIKit

final class LightImageCache: @unchecked Sendable {
    nonisolated static let shared = LightImageCache()

    nonisolated(unsafe) private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.totalCostLimit = 90 * 1024 * 1024
        cache.countLimit = 80
    }

    nonisolated func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    nonisolated func insert(_ image: UIImage, for url: URL) {
        let bytesPerPixel = 4
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        let cost = max(width * height * bytesPerPixel, 1)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    nonisolated func removeAll() {
        cache.removeAllObjects()
    }
}
