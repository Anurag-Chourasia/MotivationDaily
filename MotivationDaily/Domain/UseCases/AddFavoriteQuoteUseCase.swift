import Foundation

struct AddFavoriteQuoteUseCase {
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
            throw AppError.storage("Image is not ready yet. Please try saving again.")
        }

        let localImagePath = try favoritesRepository.storeImageData(localImageData, for: favoriteID)

        var updatedFavorites = existingFavorites
        updatedFavorites.append(
            FavoriteQuote(
                from: quote,
                imageURL: imageURL,
                localImagePath: localImagePath,
                ratioRawValue: ratioRawValue,
                imageWidth: imageWidth,
                imageHeight: imageHeight
            )
        )

        try favoritesRepository.saveFavorites(updatedFavorites)
        return updatedFavorites
    }
}

struct CacheFavoriteImageUseCase {
    private let favoritesRepository: any FavoritesRepository

    init(favoritesRepository: any FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    func execute(
        quoteID: String,
        imageData: Data,
        existingFavorites: [FavoriteQuote]
    ) throws -> [FavoriteQuote] {
        guard let index = existingFavorites.firstIndex(where: { $0.id == quoteID }) else {
            return existingFavorites
        }

        let targetFavorite = existingFavorites[index]
        if let localPath = targetFavorite.localImagePath, !localPath.isEmpty {
            return existingFavorites
        }

        let storedPath = try favoritesRepository.storeImageData(imageData, for: quoteID)

        var updatedFavorites = existingFavorites
        updatedFavorites[index] = FavoriteQuote(
            id: targetFavorite.id,
            text: targetFavorite.text,
            author: targetFavorite.author,
            source: targetFavorite.source,
            categoryKey: targetFavorite.categoryKey,
            imageURL: targetFavorite.imageURL,
            localImagePath: storedPath,
            ratioRawValue: targetFavorite.ratioRawValue,
            imageWidth: targetFavorite.imageWidth,
            imageHeight: targetFavorite.imageHeight,
            savedDate: targetFavorite.savedDate
        )

        try favoritesRepository.saveFavorites(updatedFavorites)
        return updatedFavorites
    }
}
