import Foundation

struct LoadFavoritesUseCase {
    private let repository: any FavoritesRepository

    init(repository: any FavoritesRepository) {
        self.repository = repository
    }

    func execute() throws -> [FavoriteQuote] {
        try repository.loadFavorites()
    }
}
