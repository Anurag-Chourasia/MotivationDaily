import Foundation

protocol FavoritesRepository {
    func loadFavorites() throws -> [FavoriteQuote]
    func saveFavorites(_ favorites: [FavoriteQuote]) throws
    func storeImageData(_ data: Data, for quoteID: String) throws -> String
    func removeImage(at localPath: String)
}
