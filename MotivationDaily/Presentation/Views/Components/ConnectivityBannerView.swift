import SwiftUI
import UIComponentsKit
import DesignTokensKit

struct ConnectivityBannerView: View {
    let message: String
    let isWarning: Bool
    let accent: Color

    var body: some View {
        IconMessageBanner(
            spacing: Spacing.eight,
            padding: Spacing.eight,
            font: Typography.caption,
            foreground: DesignColor.white,
            icon: {
                Image(systemName: isWarning ? "wifi.slash" : "wifi")
            },
            message: {
                Text(message)
            },
            background: {
                backgroundColor
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message))
    }

    private var backgroundColor: Color {
        isWarning ? DesignColor.red : accent
    }
}
