import SwiftUI
import DesignTokensKit

struct QuoteCardBackgroundView: View {
    let dominantColor: Color?
    let overlayOpacity: Double
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            if let dominantColor {
                dominantColor.opacity(overlayOpacity)
            } else {
                Rectangle().fill(\.black).opacity(overlayOpacity)
            }
            LinearGradient(
                stops: [ThemeColorStop(\.white, opacity: \.p0_15), ThemeColorStop(\.clear)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            LinearGradient(
                stops: [ThemeColorStop(\.black, opacity: \.p0_15), ThemeColorStop(\.clear)],
                startPoint: .bottom, endPoint: .center
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(\.white, opacity: \.p0_18, lineWidth: \.one)
        )
    }
}
