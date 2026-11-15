import SwiftUI
import LocalizationKit
import DesignTokensKit

struct QuoteCardView: View {
    let quote: Quote
    let dominantColor: Color?
    let overlayOpacity: Double
    let compactStyle: Bool
    var showsDepthEffects = true
    var cardHeight: CGFloat? = nil

    init(
        quote: Quote, dominantColor: Color? = nil, overlayOpacity: Double = 0.5,
        compactStyle: Bool = false, showsDepthEffects: Bool = true, cardHeight: CGFloat? = nil
    ) {
        self.quote = quote; self.dominantColor = dominantColor; self.overlayOpacity = overlayOpacity
        self.compactStyle = compactStyle; self.showsDepthEffects = showsDepthEffects; self.cardHeight = cardHeight
    }

    init(
        quote: Quote, dominantColorKeyPath: KeyPath<ColorTheme, Color>?, overlayOpacity: Double = 0.5,
        compactStyle: Bool = false, showsDepthEffects: Bool = true, cardHeight: CGFloat? = nil,
        colorTheme: ColorTheme = .default
    ) {
        self.init(
            quote: quote,
            dominantColor: dominantColorKeyPath != nil ? colorTheme[keyPath: dominantColorKeyPath!] : nil,
            overlayOpacity: overlayOpacity, compactStyle: compactStyle,
            showsDepthEffects: showsDepthEffects, cardHeight: cardHeight
        )
    }

    var body: some View {
        let metrics = QuoteCardMetrics(compactStyle: compactStyle, cardHeight: cardHeight)
        VStack(spacing: metrics.contentSpacing) {
            HStack {
                Image(\.quoteOpening)
                    .font(.system(size: metrics.iconSize, weight: .semibold))
                    .foregroundColor(\.white, opacity: \.p0_8)
                Spacer()
            }
            Text("\"\(quote.text)\"")
                .font(.system(size: metrics.quoteFontSize, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(metrics.lineSpacing)
                .minimumScaleFactor(\.p0_6)
                .allowsTightening(true)
                .foregroundColor(\.white)
                .padding(.horizontal, \.six)
            QuoteCardAuthorPillView(author: quote.author, fontSize: metrics.authorFontSize)
        }
        .padding(metrics.cardPadding)
        .background(
            QuoteCardBackgroundView(
                dominantColor: dominantColor,
                overlayOpacity: overlayOpacity,
                cornerRadius: metrics.cornerRadius
            )
        )
        .frame(maxWidth: .infinity, minHeight: metrics.fixedCardHeight, maxHeight: metrics.fixedCardHeight)
        .shadow(
            color: showsDepthEffects ? \.black : \.clear,
            opacity: showsDepthEffects ? \.p0_3 : nil,
            radius: showsDepthEffects ? \.sixteen : \.zero,
            y: showsDepthEffects ? \.eight : \.zero
        )
    }
}
