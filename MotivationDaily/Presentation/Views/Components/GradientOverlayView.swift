import SwiftUI
import DesignTokensKit

// MARK: - Gradient Overlay
struct GradientOverlayView: View {
    var isReducedForScroll = false

    var body: some View {
        VStack {
            LinearGradient(
                colors: [DesignColor.black.opacity(isReducedForScroll ? OpacityToken.p0_15 + OpacityToken.p0_3 / 10 : OpacityToken.p0_3 + OpacityToken.p0_15 / 1.5), DesignColor.clear],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: DesignMetric.p100)

            Spacer()

            LinearGradient(
                colors: [DesignColor.clear, DesignColor.black.opacity(isReducedForScroll ? OpacityToken.p0_35 : OpacityToken.p0_5 + OpacityToken.p0_2)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: DesignMetric.p400 - DesignMetric.p100)
        }
        .ignoresSafeArea()
    }
}
