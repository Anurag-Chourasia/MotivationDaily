import Foundation

struct AddFavoriteQuoteUseCase: Sendable {
    private let favoritesRepository: any FavoritesRepository

    init(favoritesRepository: any FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    func execute(
        quote: Quote,
        imageURL: URL?,
        localImageData: Data?,
        ratioRawValue: String?,
        imageWidth: Int?,
        imageHeight: Int?,
        existingFavorites: [FavoriteQuote]
    ) throws -> [FavoriteQuote] {
        let favoriteID = quote.id ?? quote.text
        if existingFavorites.contains(where: { $0.id == favoriteID }) {
            return existingFavorites
        }

        guard let localImageData, !localImageData.isEmpty else {
            throw AppError.imageNotReady
        }

        let localImagePath = try favoritesRepository.storeImageData(localImageData, for: favoriteID)
        let resolvedLocalImageURL = favoritesRepository.resolveImageURL(for: localImagePath)

        var updatedFavorites = existingFavorites
        updatedFavorites.append(
            FavoriteQuote(
                from: quote,
                imageURL: imageURL,
                localImagePath: localImagePath,
                ratioRawValue: ratioRawValue,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                resolvedLocalImageURL: resolvedLocalImageURL
            )
        )

        try favoritesRepository.saveFavorites(updatedFavorites)
        return updatedFavorites
    }
}
