import SwiftUI
import DesignTokensKit

struct FavoriteListView: View {
    @ObservedObject var quoteVM: QuoteViewModel
    let onImageTap: (FavoriteQuote) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.fourteen) {
                ForEach(quoteVM.favorites) { favorite in
                    let imageURL = favorite.imageURL

                    FavoriteCellView(
                        favorite: favorite,
                        imageURL: imageURL,
                        onImageTap: { onImageTap(favorite) },
                        onToggleFavorite: { quoteVM.removeFromFavorites(favorite.id) },
                        onImageDataResolved: { imageData in
                            quoteVM.cacheFavoriteImageIfNeeded(quoteID: favorite.id, imageData: imageData)
                        }
                    )
                    .padding(.horizontal, Spacing.twelve)
                }
            }
            .padding(.vertical, Spacing.twelve)
        }
        .background(DesignColor.clear)
        .accessibilityIdentifier("favorites.list")
    }
}
