import SwiftUI
import DesignTokensKit
import LocalizationKit

struct FavoritesView: View {
    @ObservedObject var quoteVM: QuoteViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.motivationL10n) private var l10n

    @State private var selectedFavorite: FavoriteQuote?
    @State private var showFullScreen = false

    var body: some View {
        NavigationView {
            ZStack {
                DesignColor.grouped.ignoresSafeArea()
                if quoteVM.favorites.isEmpty {
                    EmptyFavoritesView()
                } else {
                    FavoriteListView(
                        quoteVM: quoteVM,
                        onImageTap: { favorite in
                            selectedFavorite = favorite
                            showFullScreen = true
                        }
                    )
                }
            }
            .navigationTitle(l10n.domain.favourites)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(l10n.common.done) {
                        dismiss()
                    }
                    .accessibilityIdentifier("favorites.doneButton")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !quoteVM.favorites.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                quoteVM.clearAllFavorites()
                            } label: {
                                Label(l10n.domain.clearAll, systemImage: "trash.fill")
                            }
                        } label: {
                            Image(symbol: .ellipsisCircle)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenImageView(
                    favorite: selectedFavorite,
                    favoriteImage: nil,
                    isPresented: $showFullScreen,
                    onImageDataResolved: { quoteID, imageData in
                        quoteVM.cacheFavoriteImageIfNeeded(quoteID: quoteID, imageData: imageData)
                    }
                )
                .id(selectedFavorite?.id ?? "")
            }
            .onChange(of: showFullScreen) { visible in
                if !visible {
                    selectedFavorite = nil
                }
            }
        }
    }
}

#Preview {
    let container = AppContainer.live
    FavoritesView(quoteVM: container.makeQuoteViewModel())
}
