import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

#if DEBUG
struct ShowcaseBadgeView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: \.four) {
                Image(\.sparkles)
                    .font(\.caption2)
                Text(\.showcaseDemoTitle)
                    .font(\.caption)
                    .fontWeight(.bold)
                Text(\.showcaseDemoTapForControls)
                    .font(\.caption2)
                    .opacity(\.p0_5)
            }
            .padding(.horizontal, \.ten)
            .padding(.vertical, \.four)
            .background(.ultraThinMaterial)
            .foregroundColor(\.primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(\.primary, opacity: \.p0_35, lineWidth: \.one)
            )
        }
        .padding(.top, \.four)
        .padding(.horizontal, \.sixteen)
        .accessibilityIdentifier(.showcaseDemoIndicator)
        .accessibilityLabel(\.showcaseDemoA11y)
    }
}
#endif
