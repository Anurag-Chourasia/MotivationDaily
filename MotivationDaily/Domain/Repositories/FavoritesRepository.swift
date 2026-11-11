import Foundation

protocol FavoritesRepository: Sendable {
    func loadFavorites() throws -> [FavoriteQuote]
    func saveFavorites(_ favorites: [FavoriteQuote]) throws
    func storeImageData(_ data: Data, for quoteID: String) throws -> String
    func removeImage(at localPath: String)
    func resolveImageURL(for localPath: String) -> URL?
}

extension FavoritesRepository {
    func resolveImageURL(for localPath: String) -> URL? { nil }
}
