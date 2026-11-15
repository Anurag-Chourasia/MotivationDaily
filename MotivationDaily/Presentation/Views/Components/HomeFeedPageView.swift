import SwiftUI
import DesignTokensKit

struct HomeFeedPageView: View {
    let content: FeedPageViewModel.FeedPageContent
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets
    let ratio: WallpaperAspectRatio
    let visualEffectsReduced: Bool
    let isFavorited: Bool
    let onSelectRatio: (WallpaperAspectRatio) -> Void
    let onToggleFavorite: () -> Void
    let onShare: () -> Void

    var body: some View {
        let imageRect = HomeLayoutHelper.wallpaperRect(in: containerSize, ratio: ratio)
        let quoteLayout = QuoteCardLayout.style(for: imageRect)
        let quoteCardHeight = HomeLayoutHelper.resolvedQuoteCardHeight(for: imageRect)

        ZStack {
            Rectangle().fill(\.black).ignoresSafeArea()

            Image(uiImage: content.image)
                .resizable()
                .scaledToFill()
                .frame(width: imageRect.width, height: imageRect.height)
                .position(x: imageRect.midX, y: imageRect.midY)
                .clipped()

            GradientOverlayView(isReducedForScroll: visualEffectsReduced)

            QuoteCardContainerView(
                quote: content.quote,
                compactStyle: quoteLayout.isCompact,
                showsDepthEffects: !visualEffectsReduced,
                cardHeight: quoteCardHeight
            )
            .frame(width: quoteLayout.width, height: quoteCardHeight)
            .position(x: imageRect.midX, y: imageRect.midY)

            HomeActionRailView(
                isSaved: isFavorited,
                selectedRatio: ratio,
                onSelectRatio: onSelectRatio,
                onToggleFavorite: onToggleFavorite,
                onShare: onShare
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, \.sixteen)
            .padding(
                .bottom,
                max(safeAreaInsets.bottom + SpacingTheme.default.twentyFour, SpacingTheme.default.thirtyTwo)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
