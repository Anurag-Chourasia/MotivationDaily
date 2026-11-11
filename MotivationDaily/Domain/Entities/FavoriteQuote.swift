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

    init(
        from quote: Quote,
        imageURL: URL?,
        localImagePath: String?,
        ratioRawValue: String?,
        imageWidth: Int?,
        imageHeight: Int?,
        savedDate: Date = Date(),
        resolvedLocalImageURL: URL? = nil
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
            savedDate: savedDate,
            resolvedLocalImageURL: resolvedLocalImageURL
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, text, author, source, categoryKey, imageURL, localImagePath, ratioRawValue, imageWidth, imageHeight, savedDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.source = try container.decode(QuoteSource.self, forKey: .source)
        self.categoryKey = try container.decodeIfPresent(CategoryKey.self, forKey: .categoryKey)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        self.localImagePath = try container.decodeIfPresent(String.self, forKey: .localImagePath)
        self.ratioRawValue = try container.decodeIfPresent(String.self, forKey: .ratioRawValue)
        self.imageWidth = try container.decodeIfPresent(Int.self, forKey: .imageWidth)
        self.imageHeight = try container.decodeIfPresent(Int.self, forKey: .imageHeight)
        self.savedDate = try container.decodeIfPresent(Date.self, forKey: .savedDate) ?? Date()
        self.resolvedLocalImageURL = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(categoryKey, forKey: .categoryKey)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(localImagePath, forKey: .localImagePath)
        try container.encodeIfPresent(ratioRawValue, forKey: .ratioRawValue)
        try container.encodeIfPresent(imageWidth, forKey: .imageWidth)
        try container.encodeIfPresent(imageHeight, forKey: .imageHeight)
        try container.encode(savedDate, forKey: .savedDate)
    }

    func withLocalImagePath(_ path: String) -> FavoriteQuote {
        FavoriteQuote(
            id: id,
            text: text,
            author: author,
            source: source,
            categoryKey: categoryKey,
            imageURL: imageURL,
            localImagePath: path,
            ratioRawValue: ratioRawValue,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            savedDate: savedDate,
            resolvedLocalImageURL: nil
        )
    }

    func withResolvedLocalImageURL(_ url: URL?) -> FavoriteQuote {
        FavoriteQuote(
            id: id,
            text: text,
            author: author,
            source: source,
            categoryKey: categoryKey,
            imageURL: imageURL,
            localImagePath: localImagePath,
            ratioRawValue: ratioRawValue,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            savedDate: savedDate,
            resolvedLocalImageURL: url
        )
    }
}
