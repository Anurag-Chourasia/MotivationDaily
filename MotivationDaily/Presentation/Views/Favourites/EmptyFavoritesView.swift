import SwiftUI
import UIComponentsKit
import DesignTokensKit
import LocalizationKit

// MARK: - Empty State
struct EmptyFavoritesView: View {
    var body: some View {
        StateMessage(
            spacing: \.twelve,
            detailColor: \.secondary,
            icon: {
                Image(\.heartSlash)
                    .font(\.largeTitle)
                    .foregroundColor(\.gray)
            },
            title: {
                Text(\.emptyFavoritesTitle)
                    .font(\.headline)
                    .foregroundColor(\.gray)
            },
            detail: {
                Text(\.emptyFavoritesMessage)
                    .font(\.subheadline)
            }
        )
        .padding(\.twenty)
    }
}
