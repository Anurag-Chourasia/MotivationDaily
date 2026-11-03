import SwiftUI
import UIComponentsKit
import DesignTokensKit

struct ConnectivityBannerView: View {
    let message: String
    let isWarning: Bool
    let accent: Color

    var body: some View {
        IconMessageBanner(
            padding: SpacingTheme.default.eight,
            font: .caption,
            foreground: ColorTheme.default.white,
            icon: {
                Image(isWarning ? \.wifiSlash : \.wifi)
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
        isWarning ? ColorTheme.default.red : accent
    }
}
