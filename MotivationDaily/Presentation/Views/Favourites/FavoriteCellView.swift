import SwiftUI
import UIKit
import UIComponentsKit
import DesignTokensKit

struct FavoriteCellView: View {
    let favorite: FavoriteQuote
    let imageURL: URL?
    var imageLoader: any ImageLoading = ImageLoader.shared
    let onImageTap: () -> Void
    let onToggleFavorite: () -> Void
    let onImageDataResolved: ((Data) -> Void)?

    @State var renderedImage: UIImage?
    @State var isLoading = false
    @State var loadTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: \.zero) {
            FavoriteCellImageHeaderView(
                renderedImage: renderedImage,
                isLoading: isLoading,
                onToggleFavorite: onToggleFavorite
            )
            FavoriteCellMetaView(favorite: favorite)
        }
        .background(\.groupedSecondary)
        .cornerRadius(\.sixteen)
        .overlay(
            RoundedRectangle(cornerRadius: \.sixteen)
                .stroke(\.black, opacity: \.p0_1, lineWidth: \.one)
        )
        .shadow(color: \.black, opacity: \.p0_1, radius: \.ten, y: \.five)
        .contentShape(RoundedRectangle(cornerRadius: \.sixteen))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(.favoritesCell)
        .onTapGesture { onImageTap() }
        .onAppear { renderImageIfNeeded() }
        .onChange(of: favorite.localImagePath) { _ in
            renderedImage = nil; renderImageIfNeeded()
        }
        .onChange(of: imageURL) { _ in
            renderedImage = nil; renderImageIfNeeded()
        }
        .onDisappear { loadTask?.cancel() }
    }
}
