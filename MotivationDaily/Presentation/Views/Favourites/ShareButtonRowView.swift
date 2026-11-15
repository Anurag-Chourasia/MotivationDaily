import SwiftUI
import DesignTokensKit
import LocalizationKit

struct ShareButtonRowView: View {
    let symbol: KeyPath<SymbolTheme, AppSymbol>
    let title: KeyPath<MotivationStrings, String>
    let subtitle: KeyPath<MotivationStrings, String>
    let themeColor: KeyPath<ColorTheme, Color>

    var body: some View {
        HStack(spacing: \.ten) {
            Image(symbol)
                .font(\.title3)
            VStack(alignment: .leading, spacing: \.two) {
                Text(title)
                    .fontWeight(.semibold)
                    .font(\.body)
                Text(subtitle)
                    .font(\.caption)
                    .foregroundColor(\.white, opacity: \.p0_7)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(\.fourteen)
        .background(
            LinearGradient(
                stops: [
                    ThemeColorStop(themeColor, opacity: \.p0_8),
                    ThemeColorStop(themeColor)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(\.white)
        .cornerRadius(\.twelve)
    }
}
