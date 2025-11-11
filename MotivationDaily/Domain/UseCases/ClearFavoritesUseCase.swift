import Foundation

struct ClearFavoritesUseCase {
    private let favoritesRepository: any FavoritesRepository

    init(favoritesRepository: any FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    func execute() throws -> [FavoriteQuote] {
        let existingFavorites = try favoritesRepository.loadFavorites()
        for favorite in existingFavorites {
            if let localPath = favorite.localImagePath {
                favoritesRepository.removeImage(at: localPath)
            }
        }

        let clearedFavorites: [FavoriteQuote] = []
        try favoritesRepository.saveFavorites(clearedFavorites)
        return clearedFavorites
    }
}
