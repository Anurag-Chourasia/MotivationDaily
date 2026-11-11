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
        quote: Quote,
        dominantColor: Color? = nil,
        overlayOpacity: Double = 0.5,
        compactStyle: Bool = false,
        showsDepthEffects: Bool = true,
        cardHeight: CGFloat? = nil
    ) {
        self.quote = quote
        self.dominantColor = dominantColor
        self.overlayOpacity = overlayOpacity
        self.compactStyle = compactStyle
        self.showsDepthEffects = showsDepthEffects
        self.cardHeight = cardHeight
    }

    init(
        quote: Quote,
        dominantColorKeyPath: KeyPath<ColorTheme, Color>?,
        overlayOpacity: Double = 0.5,
        compactStyle: Bool = false,
        showsDepthEffects: Bool = true,
        cardHeight: CGFloat? = nil,
        colorTheme: ColorTheme = .default
    ) {
        self.init(
            quote: quote,
            dominantColor: dominantColorKeyPath != nil ? colorTheme[keyPath: dominantColorKeyPath!] : nil,
            overlayOpacity: overlayOpacity,
            compactStyle: compactStyle,
            showsDepthEffects: showsDepthEffects,
            cardHeight: cardHeight
        )
    }

    private var contentSpacing: CGFloat { compactStyle ? SpacingTheme.default.twelve : SpacingTheme.default.eighteen }
    private var iconSize: CGFloat { compactStyle ? DesignMetricTheme.default.p21 : DesignMetricTheme.default.p26_5 }
    private var quoteFontSize: CGFloat { compactStyle ? DesignMetricTheme.default.p19 : DesignMetricTheme.default.p22_58 }
    private var lineSpacing: CGFloat { compactStyle ? SpacingTheme.default.four : SpacingTheme.default.five }
    private var authorFontSize: CGFloat { compactStyle ? SpacingTheme.default.twelve : SpacingTheme.default.fourteen }
    private var cardPadding: CGFloat { compactStyle ? SpacingTheme.default.eighteen : SpacingTheme.default.twentyFour }
    private var cornerRadius: CGFloat { compactStyle ? CornerRadiusTheme.default.fourteen : CornerRadiusTheme.default.twenty }
    private var fixedCardHeight: CGFloat { cardHeight ?? (compactStyle ? DesignMetricTheme.default.p248 : DesignMetricTheme.default.p320) }

    var body: some View {
        VStack(spacing: contentSpacing) {
            HStack {
                Image(\.quoteOpening)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(\.white, opacity: \.p0_8)
                Spacer()
            }

            Text("\"\(quote.text)\"")
                .font(.system(size: quoteFontSize, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(lineSpacing)
                .minimumScaleFactor(\.p0_6)
                .allowsTightening(true)
                .foregroundColor(\.white)
                .padding(.horizontal, \.six)

            HStack(spacing: \.six) {
                Capsule()
                    .fill(\.white, opacity: \.p0_5)
                    .frame(width: \.p22_58, height: \.p2)
                Text(quote.author ?? String(\MotivationStrings.authorUnknown))
                    .font(.system(size: authorFontSize, weight: .semibold))
                    .foregroundColor(\.white, opacity: \.p0_9)
                Capsule()
                    .fill(\.white, opacity: \.p0_5)
                    .frame(width: \.p22_58, height: \.p2)
            }
        }
        .padding(cardPadding)
        .background(
            ZStack {
                if let dominantColor {
                    dominantColor.opacity(overlayOpacity)
                } else {
                    Rectangle()
                        .fill(\.black)
                        .opacity(overlayOpacity)
                }
                LinearGradient(
                    stops: [ThemeColorStop(\.white, opacity: \.p0_15), ThemeColorStop(\.clear)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    stops: [ThemeColorStop(\.black, opacity: \.p0_15), ThemeColorStop(\.clear)],
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(\.white, opacity: \.p0_18, lineWidth: \.one)
        )
        .frame(maxWidth: .infinity, minHeight: fixedCardHeight, maxHeight: fixedCardHeight)
        .shadow(
            color: showsDepthEffects ? \.black : \.clear,
            opacity: showsDepthEffects ? \.p0_3 : nil,
            radius: showsDepthEffects ? \.sixteen : \.zero,
            y: showsDepthEffects ? \.eight : \.zero
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(themeColors: [\.blue, \.turquoise], startPoint: .topLeading, endPoint: .bottomTrailing)

        QuoteCardView(
            quote: Quote(id: "1", text: "Life is beautiful", author: "Unknown", source: .zenQuotes, categoryKey: nil),
            dominantColorKeyPath: \.blue,
            overlayOpacity: 0.5,
            compactStyle: false,
            showsDepthEffects: true
        )
    }
}
