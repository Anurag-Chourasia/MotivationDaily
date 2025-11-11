import Foundation

struct RemoveFavoriteQuoteUseCase {
    private let favoritesRepository: any FavoritesRepository

    init(favoritesRepository: any FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    func execute(quoteID: String, existingFavorites: [FavoriteQuote]) throws -> [FavoriteQuote] {
        guard let index = existingFavorites.firstIndex(where: { $0.id == quoteID }) else {
            return existingFavorites
        }

        let removed = existingFavorites[index]
        var updatedFavorites = existingFavorites
        updatedFavorites.remove(at: index)

        if let localPath = removed.localImagePath {
            favoritesRepository.removeImage(at: localPath)
        }

        try favoritesRepository.saveFavorites(updatedFavorites)
        return updatedFavorites
    }
}
