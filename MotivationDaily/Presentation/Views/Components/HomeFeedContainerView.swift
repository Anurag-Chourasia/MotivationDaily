import SwiftUI
import DesignTokensKit

struct HomeFeedContainerView: View {
    let activeDepth: Int
    let scrollOffset: CGFloat
    let selectedCategory: CategoryKey?
    let selectedRatio: WallpaperAspectRatio
    let visualEffectsReduced: Bool
    let isConnected: Bool
    let hasError: Bool
    let isEmpty: Bool
    let cachedContent: (Int) -> FeedPageViewModel.FeedPageContent?
    let isFavorited: (Quote) -> Bool
    let onSelectRatio: (WallpaperAspectRatio) -> Void
    let onToggleFavorite: (FeedPageViewModel.FeedPageContent) -> Void
    let onShare: (FeedPageViewModel.FeedPageContent) -> Void
    let onRetry: () -> Void
    let onPrewarmCell: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack {
                feedCell(depth: activeDepth - 1, size: geo.size, insets: geo.safeAreaInsets)
                    .offset(y: scrollOffset - h)
                feedCell(depth: activeDepth, size: geo.size, insets: geo.safeAreaInsets)
                    .offset(y: scrollOffset)
                feedCell(depth: activeDepth + 1, size: geo.size, insets: geo.safeAreaInsets)
                    .offset(y: scrollOffset + h)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func feedCell(depth: Int, size: CGSize, insets: EdgeInsets) -> some View {
        if let content = cachedContent(depth) {
            HomeFeedPageView(
                content: content, containerSize: size, safeAreaInsets: insets,
                ratio: selectedRatio, visualEffectsReduced: visualEffectsReduced,
                isFavorited: isFavorited(content.quote),
                onSelectRatio: onSelectRatio,
                onToggleFavorite: { onToggleFavorite(content) },
                onShare: { onShare(content) }
            )
        } else if !isConnected || hasError {
            FeedOfflineView(onRetry: onRetry)
        } else if isEmpty {
            FeedEmptyStateView(onRetry: onRetry)
        } else {
            HomeFeedPlaceholderView(containerSize: size, ratio: selectedRatio)
                .onAppear { onPrewarmCell(depth) }
        }
    }
}
