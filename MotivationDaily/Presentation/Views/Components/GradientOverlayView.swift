import SwiftUI

// MARK: - Gradient Overlay
struct GradientOverlayView: View {
    var isReducedForScroll = false

    var body: some View {
        VStack {
            LinearGradient(
                colors: [.black.opacity(isReducedForScroll ? 0.18 : 0.4), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 100)

            Spacer()

            LinearGradient(
                colors: [.clear, .black.opacity(isReducedForScroll ? 0.35 : 0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 300)
        }
        .ignoresSafeArea()
    }
}
