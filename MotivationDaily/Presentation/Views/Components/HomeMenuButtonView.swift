import SwiftUI
import AuthKit
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct HomeMenuButtonView: View {
    let selectedAccentTheme: AccentTheme
    let user: AuthUser?
    let sessionManager: SessionManager?
    let onSelectTheme: (AccentTheme) -> Void
    let onShowFavorites: () -> Void
    let onShowAbout: () -> Void
    let onShowUserSettings: () -> Void
    let onRequestDeleteAccount: () -> Void

    var body: some View {
        Menu {
            themeMenu
            Divider()
            Button(action: onShowFavorites) { Label(\.favourites, \.heartFill) }
            Button(action: onShowAbout) { Label(\.aboutDeveloper, \.personCropCircle) }
            if let user {
                Divider()
                userSection(user)
            }
        } label: {
            Image(\.menu)
                .font(\.title3)
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
                Button(action: { onSelectTheme(theme) }) {
                    if selectedAccentTheme == theme {
                        Label(theme.localizedDisplayName, \.checkmark)
                    } else {
                        Text(theme.localizedDisplayName)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func userSection(_ user: AuthUser) -> some View {
        Section {
            Button(action: onShowUserSettings) {
                Label(user.email ?? String(\CommonStrings.accountTitle), \.personCropCircle)
            }
            Button(role: .destructive, action: { Task { await sessionManager?.signOut() } }) {
                Label(\CommonStrings.authButtonSignOut, \.rectanglePortraitAndArrowRight)
            }
            Button(role: .destructive, action: onRequestDeleteAccount) {
                Label(\CommonStrings.authButtonDeleteAccount, \.trash)
            }
        }
    }
}
