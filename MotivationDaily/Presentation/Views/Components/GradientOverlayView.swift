import SwiftUI
import DesignTokensKit

// MARK: - Gradient Overlay
struct GradientOverlayView: View {
    var isReducedForScroll = false

    var body: some View {
        VStack {
            LinearGradient(
                stops: [
                    ThemeColorStop(\.black, opacity: isReducedForScroll ? \.p0_18 : \.p0_4),
                    ThemeColorStop(\.clear)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: \.p100)

            Spacer()

            LinearGradient(
                stops: [
                    ThemeColorStop(\.clear),
                    ThemeColorStop(\.black, opacity: isReducedForScroll ? \.p0_35 : \.p0_7)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: \.p300)
        }
        .ignoresSafeArea()
    }
}
