import SwiftUI
import UIComponentsKit
import DesignTokensKit
import LocalizationKit

// MARK: - Empty State
struct EmptyFavoritesView: View {
    @Environment(\.motivationL10n) private var l10n

    var body: some View {
        StateMessage(
            spacing: Spacing.twelve,
            typography: MessageTypography(
                icon: Typography.largeTitle,
                title: Typography.headline,
                detail: Typography.subheadline
            ),
            detailColor: DesignColor.secondary,
            icon: {
                Image(symbol: .heartSlash)
                    .foregroundColor(DesignColor.gray)
            },
            title: {
                Text(l10n.domain.emptyFavoritesTitle)
                    .foregroundColor(DesignColor.gray)
            },
            detail: {
                Text(l10n.domain.emptyFavoritesMessage)
            }
        )
        .padding(.all, Spacing.twenty)
    }
}
