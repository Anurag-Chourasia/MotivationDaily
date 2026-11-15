import UIKit

#if DEBUG
actor UITestWallpaperRepository: WallpaperRepository {
    private var counter = 0
    private let outputDirectory: URL

    init() {
        let cacheRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = cacheRoot.appendingPathComponent("UITestWallpaperRepository", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        self.outputDirectory = directory
    }

    func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper {
        counter += 1
        let safeWidth = max(width, 1)
        let safeHeight = max(height, 1)
        let categoryRaw = category?.rawValue ?? "random"
        let quoteIndex = counter

        let quote = Quote(
            id: "uitest-\(categoryRaw)-\(quoteIndex)",
            text: "\(categoryRaw.capitalized) quote #\(quoteIndex)",
            author: UITestFixtureCatalog.current.author,
            source: category == nil ? .zenQuotes : .quotable,
            categoryKey: category
        )

        let imageURL = outputDirectory.appendingPathComponent(
            "uitest-\(categoryRaw)-\(safeWidth)x\(safeHeight)-\(quoteIndex).jpg"
        )
        try await MainActor.run {
            try Self.renderGradientImage(
                at: imageURL,
                width: safeWidth,
                height: safeHeight,
                categoryRaw: categoryRaw
            )
        }

        return Wallpaper(
            quote: quote,
            imageURL: imageURL,
            imageSource: .picsum,
            imageCategoryTitle: categoryRaw,
            seed: "uitest-\(categoryRaw)-\(quoteIndex)"
        )
    }

    @MainActor
    private static func renderGradientImage(
        at url: URL,
        width: Int,
        height: Int,
        categoryRaw: String
    ) throws {
        let size = CGSize(width: width, height: height)
        let seed = categoryRaw.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let colors = UITestFixtureCatalog.current.palette(for: seed)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [colors[0].cgColor, colors[1].cgColor] as CFArray,
                locations: [0, 1]
            ) else {
                colors[0].setFill()
                cgContext.fill(rect)
                return
            }
            cgContext.drawLinearGradient(
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
