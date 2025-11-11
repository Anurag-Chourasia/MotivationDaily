import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    let dominantColor: Color?
    let overlayOpacity: Double
    let compactStyle: Bool
    var showsDepthEffects = true
    var cardHeight: CGFloat? = nil

    private var contentSpacing: CGFloat { compactStyle ? 12 : 18 }
    private var iconSize: CGFloat { compactStyle ? 22 : 26 }
    private var quoteFontSize: CGFloat { compactStyle ? 19 : 23 }
    private var lineSpacing: CGFloat { compactStyle ? 4 : 5 }
    private var authorFontSize: CGFloat { compactStyle ? 12 : 14 }
    private var cardPadding: CGFloat { compactStyle ? 18 : 24 }
    private var cornerRadius: CGFloat { compactStyle ? 16 : 18 }
    private var fixedCardHeight: CGFloat { cardHeight ?? (compactStyle ? 248 : 320) }

    var body: some View {
        VStack(spacing: contentSpacing) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }

        Text("\"\(quote.text)\"")
            .font(.system(size: quoteFontSize, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.center)
            .lineSpacing(lineSpacing)
            .minimumScaleFactor(0.6)
            .allowsTightening(true)
            .foregroundColor(.white)
            .padding(.horizontal, 6)

            HStack(spacing: 6) {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 22, height: 2)
                Text(quote.author ?? "Unknown")
                    .font(.system(size: authorFontSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 22, height: 2)
            }
        }
        .padding(cardPadding)
        .background(
            ZStack {
                (dominantColor ?? Color.black)
                    .opacity(overlayOpacity)
                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [Color.black.opacity(0.15), Color.clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, minHeight: fixedCardHeight, maxHeight: fixedCardHeight)
        .shadow(
            color: showsDepthEffects ? Color.black.opacity(0.28) : .clear,
            radius: showsDepthEffects ? 16 : 0,
            x: 0,
            y: showsDepthEffects ? 8 : 0
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)

        QuoteCardView(
            quote: Quote(id: "1", text: "Life is beautiful", author: "Unknown", source: .zenQuotes, categoryKey: nil),
            dominantColor: Color.blue,
            overlayOpacity: 0.5,
            compactStyle: false,
            showsDepthEffects: true
        )
    }
}
