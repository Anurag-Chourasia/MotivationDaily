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
            id: quote.id ?? UUID().uuidString,
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
}
