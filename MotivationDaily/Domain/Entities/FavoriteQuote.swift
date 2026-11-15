import Foundation

struct FavoriteQuote: Codable, Identifiable, Equatable, Sendable {
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
    let resolvedLocalImageURL: URL?

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
        savedDate: Date = Date(),
        resolvedLocalImageURL: URL? = nil
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
        self.resolvedLocalImageURL = resolvedLocalImageURL
    }
}
