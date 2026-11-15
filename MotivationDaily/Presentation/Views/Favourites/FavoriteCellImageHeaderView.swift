import SwiftUI
import UIKit
import UIComponentsKit
import DesignTokensKit
import LocalizationKit

struct FavoriteCellImageHeaderView: View {
    let renderedImage: UIImage?
    let isLoading: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let renderedImage {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: \.p210)
                    .clipped()
            } else {
                imagePlaceholder
                    .frame(height: \.p210)
                    .clipped()
            }

            if isLoading {
                CenteredProgressOverlay(width: nil, background: \.black, opacity: \.p0_35)
                    .clipShape(Circle())
                    .frame(width: \.p40, height: \.p40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }

            Button(action: onToggleFavorite) {
                Image(\.heartFill)
                    .font(size: \.p14, weight: .bold)
                    .foregroundColor(\.red)
                    .frame(width: \.p34, height: \.p34)
                    .background(\.white, opacity: \.p0_9)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(\.black, opacity: \.p0_15, lineWidth: \.one))
            }
            .padding(\.twelve)
            .buttonStyle(.plain)
            .accessibilityLabel(\.removeFavorite)
            .accessibilityIdentifier(.favoritesRemoveButton)
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                stops: [ThemeColorStop(\.black, opacity: \.p0_5), ThemeColorStop(\.black, opacity: \.p0_7)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(\.photo).font(\.title).foregroundColor(\.white, opacity: \.p0_7)
        }
    }
}
