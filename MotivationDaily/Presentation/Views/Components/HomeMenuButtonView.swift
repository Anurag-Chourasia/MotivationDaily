import SwiftUI
import AuthKit
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct HomeMenuButtonView: View {
    let selectedAccentTheme: AccentTheme
    let user: AuthUser?
    let sessionManager: SessionManager?
    let actions: HomeTopChromeActions

    var body: some View {
        Menu {
            Section {
                Button(action: actions.onShowUserSettings) {
                    Label(user?.email ?? String(\CommonStrings.accountTitle), \.personCropCircle)
                }
            }
            Divider()
            themeMenu
            Divider()
            Button(action: actions.onShowFavorites) { Label(\.favourites, \.heartFill) }
            Button(action: actions.onShowAbout) { Label(\.aboutDeveloper, \.personCropCircle) }
        } label: {
            Image(\.menu)
                .font(\.title)
                .imageScale(.large)
                .foregroundColor(selectedAccentTheme.color)
                .frame(width: \.p44, height: \.p44)
                .contentShape(Rectangle())
                .accessibilityIdentifier(.contentMenuButton)
        }
    }

    private var themeMenu: some View {
        Menu(
            String(
                format: String(\MotivationStrings.themeMenu),
                locale: LocalizationController.shared.locale,
                selectedAccentTheme.localizedDisplayName
            )
        ) {
            ForEach(AccentTheme.allCases) { theme in
                Button(action: { actions.onSelectTheme(theme) }) {
                    if selectedAccentTheme == theme {
                        Label(theme.localizedDisplayName, \.checkmark)
                    } else {
                        Text(theme.localizedDisplayName)
                    }
                }
            }
        }
    }
}
