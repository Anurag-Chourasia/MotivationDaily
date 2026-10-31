import SwiftUI
import UIKit
import UIComponentsKit
import DesignTokensKit

struct FavoriteCellView: View {
    let favorite: FavoriteQuote
    let imageURL: URL?
    let onImageTap: () -> Void
    let onToggleFavorite: () -> Void
    let onImageDataResolved: ((Data) -> Void)?

    @State private var renderedImage: UIImage?
    @State private var isLoading = false
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.zero) {
            ZStack(alignment: .topTrailing) {
                if let renderedImage {
                    Image(uiImage: renderedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 210)
                        .clipped()
                } else {
                    imagePlaceholder
                        .frame(height: 210)
                        .clipped()
                }

                if isLoading {
                    CenteredProgressOverlay(
                        width: nil,
                        label: { EmptyView() },
                        background: { DesignColor.black.opacity(OpacityToken.p0_35) }
                    )
                    .clipShape(Circle())
                    .frame(width: DesignMetric.p40, height: DesignMetric.p40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }

                Button(action: onToggleFavorite) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: Spacing.fourteen, weight: .bold))
                        .foregroundColor(DesignColor.red)
                        .frame(width: DesignMetric.p34, height: DesignMetric.p34)
                        .background(DesignColor.white.opacity(0.92))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(DesignColor.black.opacity(0.12), lineWidth: StrokeWidth.one)
                        )
                }
                .padding(Spacing.twelve)
                .buttonStyle(.plain)
                .accessibilityLabel("Remove Favorite")
                .accessibilityIdentifier("favorites.removeButton")
            }

            VStack(alignment: .leading, spacing: Spacing.ten) {
                Text("\"\(favorite.text)\"")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignColor.primary)
                    .lineSpacing(DesignMetric.p3)

                HStack(spacing: Spacing.eight) {
                    tagPill(text: categoryTag)
                    tagPill(text: sourceTag)
                }

                Text("— \(favorite.author ?? "Unknown")")
                    .font(.system(size: Spacing.fourteen, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(DesignColor.secondary)
            }
            .padding(Spacing.fourteen)
        }
        .background(DesignColor.groupedSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignMetric.p16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignMetric.p16, style: .continuous)
                .stroke(DesignColor.black.opacity(0.08), lineWidth: StrokeWidth.one)
        )
        .shadow(color: DesignColor.black.opacity(0.07), radius: Spacing.ten, x: 0, y: Spacing.five)
        .contentShape(RoundedRectangle(cornerRadius: DesignMetric.p16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("favorites.cell")
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
                colors: [Color.black.opacity(0.5), Color.black.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "photo")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var categoryTag: String {
        guard let raw = favorite.categoryKey?.rawValue, !raw.isEmpty else {
            return "Random"
        }
        return raw
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private var sourceTag: String {
        switch favorite.source {
        case .zenQuotes:
            return "ZenQuotes"
        case .quotable:
            return "Quotable"
        case .quoteGarden:
            return "QuoteGarden"
        case .adviceSlip:
            return "AdviceSlip"
        }
    }

    private func tagPill(text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
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
