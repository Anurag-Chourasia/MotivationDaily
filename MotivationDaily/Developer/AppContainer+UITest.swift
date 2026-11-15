import Foundation

#if DEBUG
extension AppContainer {
    static func seedUITestFavoritesIfNeeded(using favoritesRepository: any FavoritesRepository) {
        let fixture = UITestFixtureCatalog.current
        let seedFavorite = FavoriteQuote(
            id: fixture.favorite.id,
            text: fixture.favorite.text,
            author: fixture.author,
            source: .adviceSlip,
            categoryKey: nil,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "9:16",
            imageWidth: 390,
            imageHeight: 844
        )

        do {
            let existing = try favoritesRepository.loadFavorites()
            guard existing.isEmpty else { return }
            try favoritesRepository.saveFavorites([seedFavorite])
        } catch {
            try? favoritesRepository.saveFavorites([seedFavorite])
        }
    }
}
#endif
