import SwiftUI
import DesignTokensKit

struct QuoteCardView: View {
    let quote: Quote
    let dominantColor: Color?
    let overlayOpacity: Double
    let compactStyle: Bool
    var showsDepthEffects = true
    var cardHeight: CGFloat? = nil

    private var contentSpacing: CGFloat { compactStyle ? Spacing.twelve : DesignMetric.p18 }
    private var iconSize: CGFloat { compactStyle ? DesignMetric.p21 : DesignMetric.p26_5 }
    private var quoteFontSize: CGFloat { compactStyle ? DesignMetric.p19 : DesignMetric.p22_58 }
    private var lineSpacing: CGFloat { compactStyle ? Spacing.four : Spacing.five }
    private var authorFontSize: CGFloat { compactStyle ? Spacing.twelve : Spacing.fourteen }
    private var cardPadding: CGFloat { compactStyle ? DesignMetric.p18 : DesignMetric.p24 }
    private var cornerRadius: CGFloat { compactStyle ? CornerRadius.fourteen : CornerRadius.twenty }
    private var fixedCardHeight: CGFloat { cardHeight ?? (compactStyle ? DesignMetric.p400 - DesignMetric.p140 - DesignMetric.p12 : DesignMetric.p400 - DesignMetric.p80) }

    var body: some View {
        VStack(spacing: contentSpacing) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(DesignColor.white.opacity(OpacityToken.p0_5 + OpacityToken.p0_3))
                Spacer()
            }

            Text("\"\(quote.text)\"")
                .font(.system(size: quoteFontSize, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(lineSpacing)
                .minimumScaleFactor(OpacityToken.p0_5 + OpacityToken.p0_15 / 1.5)
                .allowsTightening(true)
                .foregroundColor(DesignColor.white)
                .padding(.horizontal, CornerRadius.six)

            HStack(spacing: CornerRadius.six) {
                Capsule()
                    .fill(DesignColor.white.opacity(OpacityToken.p0_5))
                    .frame(width: DesignMetric.p22_58, height: StrokeWidth.two)
                Text(quote.author ?? "Unknown")
                    .font(.system(size: authorFontSize, weight: .semibold))
                    .foregroundColor(DesignColor.white.opacity(OpacityToken.p0_5 + OpacityToken.p0_35 + OpacityToken.p0_15 / 3))
                Capsule()
                    .fill(DesignColor.white.opacity(OpacityToken.p0_5))
                    .frame(width: DesignMetric.p22_58, height: StrokeWidth.two)
            }
        }
        .padding(cardPadding)
        .background(
            ZStack {
                (dominantColor ?? DesignColor.black)
                    .opacity(overlayOpacity)
                LinearGradient(
                    colors: [DesignColor.white.opacity(OpacityToken.p0_15), DesignColor.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [DesignColor.black.opacity(OpacityToken.p0_15), DesignColor.clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(DesignColor.white.opacity(OpacityToken.p0_15 + OpacityToken.p0_3 / 10), lineWidth: StrokeWidth.one)
        )
        .frame(maxWidth: .infinity, minHeight: fixedCardHeight, maxHeight: fixedCardHeight)
        .shadow(
            color: showsDepthEffects ? DesignColor.black.opacity(OpacityToken.p0_2 + OpacityToken.p0_3 / 3.75) : DesignColor.clear,
            radius: showsDepthEffects ? Spacing.sixteen : 0,
            x: 0,
            y: showsDepthEffects ? Spacing.eight : 0
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [DesignColor.blue, DesignColor.turquoise], startPoint: .topLeading, endPoint: .bottomTrailing)

        QuoteCardView(
            quote: Quote(id: "1", text: "Life is beautiful", author: "Unknown", source: .zenQuotes, categoryKey: nil),
            dominantColor: DesignColor.blue,
            overlayOpacity: OpacityToken.p0_5,
            compactStyle: false,
            showsDepthEffects: true
        )
    }
}
