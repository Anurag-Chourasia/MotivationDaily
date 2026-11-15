import Foundation

struct CacheFavoriteImageUseCase: Sendable {
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
