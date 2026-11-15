import Foundation

extension FavoriteQuote {
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
}
