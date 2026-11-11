import SwiftUI
import DesignTokensKit
import LocalizationKit

struct FeedOfflineView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: \.sixteen) {
            Image(\.wifiSlash)
                .font(\.largeTitle)
                .foregroundColor(\.white, opacity: \.p0_7)

            Text(\.connectivityOffline)
                .font(\.headline)
                .foregroundColor(\.white)

            Text(\.recoveryNetwork)
                .font(\.subheadline)
                .foregroundColor(\.white, opacity: \.p0_7)
                .multilineTextAlignment(.center)
                .padding(.horizontal, \.thirtyTwo)

            Button(action: onRetry) {
                HStack(spacing: \.eight) {
                    Image(\.arrowClockwise)
                    Text(\CommonStrings.retry)
                }
                .font(\.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(\.white)
                .padding(.horizontal, \.twenty)
                .padding(.vertical, \.ten)
                .background(
                    Capsule()
                        .fill(\.white, opacity: \.p0_2)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                themeColors: [\.black, \.ink, \.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
