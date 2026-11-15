import SwiftUI
import DesignTokensKit

struct FullScreenQuoteCardOverlay: View {
    let favorite: FavoriteQuote
    let imageRect: CGRect
    let canvasSize: CGSize

    var body: some View {
        let style = QuoteCardLayout.style(for: imageRect)
        let height = FullScreenImageLayoutHelper.resolvedQuoteCardHeight(for: imageRect)
        let quote = Quote(
            id: favorite.id,
            text: favorite.text,
            author: favorite.author,
            source: favorite.source,
            categoryKey: favorite.categoryKey
        )

        QuoteCardView(
            quote: quote,
            dominantColor: nil,
            overlayOpacity: 0.5,
            compactStyle: style.isCompact,
            showsDepthEffects: true,
            cardHeight: height
        )
        .frame(width: style.width, height: height)
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .center)
    }
}
