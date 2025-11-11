import SwiftUI

struct QuoteCardContainerView: View {
    let quote: Quote
    let compactStyle: Bool
    var showsDepthEffects = true
    var cardHeight: CGFloat? = nil

    var body: some View {
        quoteCardView
            .frame(maxWidth: .infinity)
    }

    private var quoteCardView: some View {
        QuoteCardView(
            quote: quote,
            dominantColor: nil,
            overlayOpacity: 0.5,
            compactStyle: compactStyle,
            showsDepthEffects: showsDepthEffects,
            cardHeight: cardHeight
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)

        QuoteCardContainerView(
            quote: Quote(id: "1", text: "Life is beautiful", author: "Unknown", source: .zenQuotes, categoryKey: nil),
            compactStyle: false
        )
    }
}
