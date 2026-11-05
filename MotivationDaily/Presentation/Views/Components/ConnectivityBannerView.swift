import SwiftUI
import UIComponentsKit
import DesignTokensKit

struct ConnectivityBannerView: View {
    let message: String
    let isWarning: Bool
    let accent: Color

    var body: some View {
        OfflineBannerView(
            message: message,
            isWarning: isWarning,
            backgroundColor: isWarning ? ColorTheme.default.red : accent
        )
    }
}
