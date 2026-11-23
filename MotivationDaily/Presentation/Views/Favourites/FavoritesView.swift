import SwiftUI
import UIComponentsKit
import DesignTokensKit
import LocalizationKit

struct FavoritesView: View {
    @ObservedObject var quoteVM: QuoteViewModel
    var imageLoader: any ImageLoading = ImageLoader.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFavorite: FavoriteQuote?
    @State private var selectedImage: UIImage?
    @State private var showFullScreen = false

    var body: some View {
        NavigationView {
            Group {
                if quoteVM.favorites.isEmpty {
                    EmptyFavoritesView()
                } else {
                    FavoriteListView(
                        quoteVM: quoteVM,
                        imageLoader: imageLoader,
                        onImageTap: { favorite, img in
                            selectedFavorite = favorite
                            selectedImage = img
                            showFullScreen = true
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(\.black)
            .navigationTitle(Text(\.favourites))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(\.done) {
                        dismiss()
                    }
                    .accessibilityIdentifier(.favoritesDoneButton)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !quoteVM.favorites.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                quoteVM.clearAllFavorites()
                            } label: {
                                Label(\.clearAll, \.trashFill)
                            }
                        } label: {
                            Image(\.ellipsisCircle)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenImageView(
                    favorite: selectedFavorite,
                    favoriteImage: selectedImage,
                    imageLoader: imageLoader,
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
                    selectedImage = nil
                }
            }
        }
    }
}

#Preview {
    let container = AppContainer.preview
    FavoritesView(quoteVM: container.makeQuoteViewModel())
}
