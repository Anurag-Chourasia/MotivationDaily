import SwiftUI

struct FavoritesView: View {
    @ObservedObject var quoteVM: QuoteViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFavorite: FavoriteQuote?
    @State private var showFullScreen = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.03).ignoresSafeArea()
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
            .navigationTitle("❤️ Favorite Quotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
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
                                Label("Clear All", systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
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
