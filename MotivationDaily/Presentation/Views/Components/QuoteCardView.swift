import SwiftUI
import DesignTokensKit

struct QuoteCardView: View {
    let quote: Quote
    let dominantColor: Color?
    let overlayOpacity: Double
    let compactStyle: Bool
    var showsDepthEffects = true
    var cardHeight: CGFloat? = nil

    private var contentSpacing: CGFloat { compactStyle ? SpacingTheme.default.twelve : DesignMetric.p18 }
    private var iconSize: CGFloat { compactStyle ? DesignMetric.p21 : DesignMetric.p26_5 }
    private var quoteFontSize: CGFloat { compactStyle ? DesignMetric.p19 : DesignMetric.p22_58 }
    private var lineSpacing: CGFloat { compactStyle ? SpacingTheme.default.four : SpacingTheme.default.five }
    private var authorFontSize: CGFloat { compactStyle ? SpacingTheme.default.twelve : SpacingTheme.default.fourteen }
    private var cardPadding: CGFloat { compactStyle ? DesignMetric.p18 : DesignMetric.p24 }
    private var cornerRadius: CGFloat { compactStyle ? CornerRadiusTheme.default.fourteen : CornerRadiusTheme.default.twenty }
    private var fixedCardHeight: CGFloat { cardHeight ?? (compactStyle ? DesignMetric.p248 : DesignMetric.p320) }

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
                Text(quote.author ?? "Unknown")
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
                (dominantColor ?? ColorTheme.default.black)
                    .opacity(overlayOpacity)
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
            color: showsDepthEffects ? ColorTheme.default.black.opacity(OpacityTheme.default.p0_3) : ColorTheme.default.clear,
            radius: showsDepthEffects ? 16 : 0,
            x: 0,
            y: showsDepthEffects ? 8 : 0
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(themeColors: [\.blue, \.turquoise], startPoint: .topLeading, endPoint: .bottomTrailing)

        QuoteCardView(
            quote: Quote(id: "1", text: "Life is beautiful", author: "Unknown", source: .zenQuotes, categoryKey: nil),
            dominantColor: ColorTheme.default.blue,
            overlayOpacity: 0.5,
            compactStyle: false,
            showsDepthEffects: true
        )
    }
}
