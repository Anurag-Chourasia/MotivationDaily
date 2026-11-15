import Foundation

extension FavoriteQuote {
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
