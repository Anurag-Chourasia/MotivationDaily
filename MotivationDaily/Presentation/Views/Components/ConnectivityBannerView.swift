import SwiftUI

struct ConnectivityBannerView: View {
    let message: String
    let isWarning: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isWarning ? "wifi.slash" : "wifi")
                .accessibilityHidden(true)
            Text(message)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(message))
    }

    private var backgroundColor: Color {
        isWarning ? Color.red : accent
    }
}
