import Foundation
import UIKit

#if DEBUG
extension FeedCatalogueStore {
    static func makeUITestStore(
        apiService: APIService,
        quotableClient: QuotableClient,
        zenClient: ZenQuotesClient,
        adviceSlipClient: AdviceSlipClient
    ) -> FeedCatalogueStore {
        let cacheRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let uiTestRoot = cacheRoot.appendingPathComponent("feed-catalogue-uitest", isDirectory: true)
        let seededSnapshot = makeUITestSnapshot(cacheRoot: uiTestRoot)

        return FeedCatalogueStore(
            apiService: apiService,
            quotableClient: quotableClient,
            zenClient: zenClient,
            adviceSlipClient: adviceSlipClient,
            cacheRootURL: uiTestRoot,
            allowsNetworkSync: false,
            seededSnapshot: seededSnapshot
        )
    }

    private static func makeUITestSnapshot(cacheRoot: URL) -> Snapshot {
        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: cacheRoot, withIntermediateDirectories: true)

        let imagesDirectory = cacheRoot.appendingPathComponent("images", isDirectory: true)
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let fixture = UITestFixtureCatalog.current
        var images: [CatalogueImageMeta] = []
        for index in 0..<fixture.randomQuoteCount {
            let width = index.isMultiple(of: 2) ? 900 : 1200
            let height = index.isMultiple(of: 2) ? 1600 : 800
            let fileURL = imagesDirectory.appendingPathComponent("uitest-image-\(index).jpg")
            if !fileManager.fileExists(atPath: fileURL.path) {
                try? renderUITestImage(at: fileURL, width: width, height: height, seed: index)
            }

            let meta = CatalogueImageMeta(
                id: "uitest-\(index)",
                author: fixture.author,
                width: width,
                height: height,
                url: fileURL,
                downloadURL: fileURL
            )
            images.append(meta)
        }

        let randomQuotes = (0..<fixture.randomQuoteCount).map { index in
            Quote(
                id: "uitest-random-\(index)",
                text: "Random quote #\(index + 1)",
                author: fixture.author,
                source: .zenQuotes,
                categoryKey: nil
            )
        }

        let categories = fixture.categories.map {
            CatalogueCategory(keyRawValue: $0.key, displayName: $0.name, quoteCount: $0.quoteCount)
        }
        var quotesByCategory = [Snapshot.randomKey: randomQuotes]
        for category in fixture.categories {
            quotesByCategory[category.key] = (0..<category.quoteCount).map { index in
                Quote(id: "uitest-\(category.key)-\(index)", text: "\(category.name) quote #\(index + 1)",
                      author: fixture.author, source: .quotable, categoryKey: CategoryKey(rawValue: category.key))
            }
        }

        return Snapshot(
            categories: categories,
            randomQuotes: randomQuotes,
            quotesByCategory: quotesByCategory,
            images: images,
            updatedAt: Date()
        )
    }

    private static func renderUITestImage(at url: URL, width: Int, height: Int, seed: Int) throws {
        let size = CGSize(width: max(width, 1), height: max(height, 1))
        let colors = UITestFixtureCatalog.current.palette(for: seed)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [colors[0].cgColor, colors[1].cgColor] as CFArray,
                locations: [0, 1]
            ) else {
                colors[0].setFill()
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

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw AppError.unknown("Failed to render UI test wallpaper image.")
        }
        try data.write(to: url, options: .atomic)
    }
}
#endif
