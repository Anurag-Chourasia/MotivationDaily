import Foundation

struct FavoriteQuote: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let author: String?
    let source: QuoteSource
    let categoryKey: CategoryKey?
    let imageURL: URL?
    let localImagePath: String?
    let ratioRawValue: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let savedDate: Date

    init(
        id: String,
        text: String,
        author: String?,
        source: QuoteSource,
        categoryKey: CategoryKey?,
        imageURL: URL?,
        localImagePath: String?,
        ratioRawValue: String?,
        imageWidth: Int?,
        imageHeight: Int?,
        savedDate: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.source = source
        self.categoryKey = categoryKey
        self.imageURL = imageURL
        self.localImagePath = localImagePath
        self.ratioRawValue = ratioRawValue
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.savedDate = savedDate
    }

    init(
        from quote: Quote,
        imageURL: URL?,
        localImagePath: String?,
        ratioRawValue: String?,
        imageWidth: Int?,
        imageHeight: Int?,
        savedDate: Date = Date()
    ) {
        self.init(
            id: quote.id ?? quote.text,
            text: quote.text,
            author: quote.author,
            source: quote.source,
            categoryKey: quote.categoryKey,
            imageURL: imageURL,
            localImagePath: localImagePath,
            ratioRawValue: ratioRawValue,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            savedDate: savedDate
        )
    }

    var resolvedLocalImageURL: URL? {
        guard let localImagePath, !localImagePath.isEmpty else { return nil }

        let filename = localImagePath.hasPrefix("/")
            ? URL(fileURLWithPath: localImagePath).lastPathComponent
            : localImagePath

        let baseDirectory =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = baseDirectory.appendingPathComponent("FavoriteImages", isDirectory: true).appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }

        if localImagePath.hasPrefix("/"), FileManager.default.fileExists(atPath: localImagePath) {
            return URL(fileURLWithPath: localImagePath)
        }

        return nil
    }
}
