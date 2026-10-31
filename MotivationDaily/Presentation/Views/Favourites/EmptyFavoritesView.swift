import SwiftUI
import UIComponentsKit
import DesignTokensKit

// MARK: - Empty State
struct EmptyFavoritesView: View {
    var body: some View {
        StateMessage(
            spacing: Spacing.twelve,
            typography: MessageTypography(
                icon: .system(size: 56),
                title: Typography.headline,
                detail: Typography.subheadline
            ),
            detailColor: DesignColor.secondary,
            icon: {
                Image(systemName: "heart.slash")
                    .foregroundColor(DesignColor.gray)
            },
            title: {
                Text("No Favorites Yet")
                    .foregroundColor(DesignColor.gray)
            },
            detail: {
                Text("Quotes you mark as favorite will appear here.")
            }
        )
        .padding(.all, Spacing.twenty)
    }
}
