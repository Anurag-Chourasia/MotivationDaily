import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct HomeFeedPlaceholderView: View {
    let containerSize: CGSize
    let ratio: WallpaperAspectRatio

    var body: some View {
        let imageRect = HomeLayoutHelper.wallpaperRect(in: containerSize, ratio: ratio)
        let quoteLayout = QuoteCardLayout.style(for: imageRect)
        let quoteCardHeight = HomeLayoutHelper.resolvedQuoteCardHeight(for: imageRect)

        ZStack {
            LinearGradient(
                themeColors: [\.black, \.ink, \.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RoundedRectangle(cornerRadius: quoteLayout.isCompact ? \.fourteen : \.twenty)
                .fill(\.white, opacity: \.p0_1)
                .overlay(
                    RoundedRectangle(cornerRadius: quoteLayout.isCompact ? \.fourteen : \.twenty)
                        .stroke(\.white, opacity: \.p0_18, lineWidth: \.one)
                )
                .frame(width: quoteLayout.width, height: quoteCardHeight)
                .position(x: imageRect.midX, y: imageRect.midY)

            CenteredProgressOverlay(width: nil, background: \.clear)
                .tint(\.white, opacity: \.p0_9)
                .scaleEffect(ScaleToken.p1_0)
        }
    }
}
