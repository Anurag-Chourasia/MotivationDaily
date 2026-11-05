import SwiftUI
import UIKit
import UIComponentsKit
import DesignTokensKit
import LocalizationKit

struct FavoriteCellView: View {
    let favorite: FavoriteQuote
    let imageURL: URL?
    let onImageTap: () -> Void
    let onToggleFavorite: () -> Void
    let onImageDataResolved: ((Data) -> Void)?

    @Environment(\.motivationL10n) private var l10n
    @State private var renderedImage: UIImage?
    @State private var isLoading = false
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: \.zero) {
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
                    CenteredProgressOverlay(
                        width: nil,
                        background: \.black,
                        opacity: \.p0_35
                    )
                    .clipShape(Circle())
                    .frame(width: \.p40, height: \.p40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }

                Button(action: onToggleFavorite) {
                    favoriteHeartButton
                }
                .padding(\.twelve)
                .buttonStyle(.plain)
                .accessibilityLabel(\.removeFavorite)
                .accessibilityIdentifier(.favoritesRemoveButton)
            }

            VStack(alignment: .leading, spacing: \.ten) {
                Text("\"\(favorite.text)\"")
                    .font(\.headline)
                    .foregroundColor(\.primary)
                    .lineSpacing(\.p3)

                HStack(spacing: \.eight) {
                    categoryTagView
                    tagPill(favorite.source.titleKeyPath)
                }

                Text("— \(favorite.author ?? String(\MotivationStrings.authorUnknown))")
                    .font(\.subheadline)
                    .italic()
                    .foregroundColor(\.secondary)
            }
            .padding(\.fourteen)
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
        .onTapGesture {
            onImageTap()
        }
        .onAppear {
            renderImageIfNeeded()
        }
        .onChange(of: favorite.localImagePath) { _ in
            renderedImage = nil
            renderImageIfNeeded()
        }
        .onChange(of: imageURL) { _ in
            renderedImage = nil
            renderImageIfNeeded()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                stops: [
                    ThemeColorStop(\.black, opacity: \.p0_5),
                    ThemeColorStop(\.black, opacity: \.p0_7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(\.photo)
                .font(\.title)
                .foregroundColor(\.white, opacity: \.p0_7)
        }
    }

    @ViewBuilder
    private var categoryTagView: some View {
        if let raw = favorite.categoryKey?.rawValue, !raw.isEmpty {
            tagPill(verbatim: raw.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ").capitalized)
        } else {
            tagPill(\.randomCategory)
        }
    }

    private var favoriteHeartButton: some View {
        Image(\.heartFill)
            .font(size: \.p14, weight: .bold)
            .foregroundColor(\.red)
            .frame(width: \.p34, height: \.p34)
            .background(\.white, opacity: \.p0_9)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(\.black, opacity: \.p0_15, lineWidth: \.one)
            )
    }

    private func tagPill(_ keyPath: KeyPath<MotivationStrings, String>) -> some View {
        Text(keyPath)
            .font(\.caption2)
            .foregroundColor(\.secondary)
            .padding(.horizontal, \.eight)
            .padding(.vertical, \.four)
            .background(\.grouped)
            .clipShape(Capsule())
    }

    private func tagPill(verbatim: String) -> some View {
        Text(verbatim.uppercased())
            .font(\.caption2)
            .foregroundColor(\.secondary)
            .padding(.horizontal, \.eight)
            .padding(.vertical, \.four)
            .background(\.grouped)
            .clipShape(Capsule())
    }

    private func renderImageIfNeeded() {
        loadTask?.cancel()
        guard renderedImage == nil else { return }

        if let localURL = favorite.resolvedLocalImageURL,
           let localImage = UIImage(contentsOfFile: localURL.path) {
            renderedImage = localImage
            isLoading = false
            return
        }

        guard let url = imageURL else {
            isLoading = false
            return
        }

        if let cached = LightImageCache.shared.image(for: url) {
            renderedImage = cached
            isLoading = false
            persistImageIfNeeded(from: cached)
            return
        }

        isLoading = true
        loadTask = Task {
            let cachedOnlyImage = await ImageLoader.shared.cachedImage(for: url)
            if Task.isCancelled { return }
            await MainActor.run {
                if let cachedOnlyImage {
                    renderedImage = cachedOnlyImage
                    persistImageIfNeeded(from: cachedOnlyImage)
                }
                isLoading = false
            }
        }
    }

    private func persistImageIfNeeded(from image: UIImage) {
        guard favorite.localImagePath?.isEmpty ?? true else {
            return
        }
        let callback = onImageDataResolved
        DispatchQueue.global(qos: .utility).async {
            guard let imageData = image.jpegData(compressionQuality: 0.88) else {
                return
            }
            DispatchQueue.main.async {
                callback?(imageData)
            }
        }
    }
}
