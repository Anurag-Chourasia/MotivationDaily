import Foundation
import Combine

@MainActor
final class QuoteViewModel: ObservableObject {
    @Published var favorites: [FavoriteQuote] = []
    @Published var quoteError: String?

    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let loadFavoritesUseCase: LoadFavoritesUseCase
    private let addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase
    private let cacheFavoriteImageUseCase: CacheFavoriteImageUseCase
    private let removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase
    private let clearFavoritesUseCase: ClearFavoritesUseCase

    init(
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        loadFavoritesUseCase: LoadFavoritesUseCase,
        addFavoriteQuoteUseCase: AddFavoriteQuoteUseCase,
        cacheFavoriteImageUseCase: CacheFavoriteImageUseCase,
        removeFavoriteQuoteUseCase: RemoveFavoriteQuoteUseCase,
        clearFavoritesUseCase: ClearFavoritesUseCase
    ) {
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.loadFavoritesUseCase = loadFavoritesUseCase
        self.addFavoriteQuoteUseCase = addFavoriteQuoteUseCase
        self.cacheFavoriteImageUseCase = cacheFavoriteImageUseCase
        self.removeFavoriteQuoteUseCase = removeFavoriteQuoteUseCase
        self.clearFavoritesUseCase = clearFavoritesUseCase

        loadFavorites()
    }

    func fetchCategories() async throws -> [Category] {
        try await fetchCategoriesUseCase.execute()
    }

    func addToFavorites(
        _ quote: Quote,
        imageURL: URL? = nil,
        localImageData: Data? = nil,
        ratioRawValue: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil
    ) {
        do {
            favorites = try addFavoriteQuoteUseCase.execute(
                quote: quote,
                imageURL: imageURL,
                localImageData: localImageData,
                ratioRawValue: ratioRawValue,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                existingFavorites: favorites
            )
        } catch {
            quoteError = userFacingMessage(for: error)
        }
    }

    func removeFromFavorites(_ quoteID: String) {
        do {
            favorites = try removeFavoriteQuoteUseCase.execute(
                quoteID: quoteID,
                existingFavorites: favorites
            )
        } catch {
            quoteError = userFacingMessage(for: error)
        }
    }

    func removeFromFavorites(quote: Quote) {
        if let id = quote.id, let favorite = favorites.first(where: { $0.id == id || $0.text == quote.text }) {
            removeFromFavorites(favorite.id)
        } else if let favorite = favorites.first(where: { $0.text == quote.text }) {
            removeFromFavorites(favorite.id)
        } else if let id = quote.id {
            removeFromFavorites(id)
        }
    }

    func isFavorited(_ quoteID: String?) -> Bool {
        guard let quoteID else { return false }
        return favorites.contains { $0.id == quoteID }
    }

    func isFavorited(quote: Quote?) -> Bool {
        guard let quote else { return false }
        if let id = quote.id, !id.isEmpty {
            return favorites.contains { $0.id == id || $0.text == quote.text }
        }
        return favorites.contains { $0.text == quote.text }
    }

    func getFavorite(_ quoteID: String) -> FavoriteQuote? {
        favorites.first { $0.id == quoteID }
    }

    func cacheFavoriteImageIfNeeded(quoteID: String, imageData: Data) {
        guard !quoteID.isEmpty else { return }
        guard let existing = getFavorite(quoteID) else { return }
        if let localPath = existing.localImagePath, !localPath.isEmpty {
            return
        }

        do {
            favorites = try cacheFavoriteImageUseCase.execute(
                quoteID: quoteID,
                imageData: imageData,
                existingFavorites: favorites
            )
        } catch {
            quoteError = userFacingMessage(for: error)
        }
    }

    func clearAllFavorites() {
        do {
            favorites = try clearFavoritesUseCase.execute()
        } catch {
            quoteError = userFacingMessage(for: error)
        }
    }

    private func loadFavorites() {
        do {
            favorites = try loadFavoritesUseCase.execute()
        } catch {
            favorites = []
            quoteError = userFacingMessage(for: error)
        }
    }

    private func userFacingMessage(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "Something went wrong."
        }
        if let local = error as? LocalizedError, let description = local.errorDescription {
            return description
        }
        return "Something went wrong."
    }
}
