import SwiftUI
import AuthKit
import DesignTokensKit
import LocalizationKit

struct HomeTopChromeView: View {
    let selectedAccentTheme: AccentTheme
    let user: AuthUser?
    let sessionManager: SessionManager?
    let tabs: [CategoryTabItem]
    let selectedCategory: CategoryKey?
    let banner: (show: Bool, message: String, isWarning: Bool)
    var namespace: Namespace.ID
    let actions: HomeTopChromeActions

    var body: some View {
        VStack(spacing: \.eight) {
            topBarRow
            HomeCategoryBarView(
                tabs: tabs,
                selectedCategory: selectedCategory,
                selectedAccentTheme: selectedAccentTheme,
                onSelectCategory: actions.onSelectCategory,
                namespace: namespace
            )
            .frame(height: \.p55).padding(.horizontal, \.twelve)

            if banner.show {
                ConnectivityBannerView(
                    message: banner.message, isWarning: banner.isWarning, accent: selectedAccentTheme.color
                )
                .padding(.horizontal, \.twelve)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.bottom, \.eight).background(chromeBackground)
    }

    private var topBarRow: some View {
        ZStack {
            Text(\.motivationAppName)
                .font(\.headline).minimumScaleFactor(\.p0_8)
                .foregroundColor(selectedAccentTheme.color)
            HStack {
                Rectangle().fill(\.clear).frame(width: \.p44, height: \.p44)
                Spacer()
                HomeMenuButtonView(
                    selectedAccentTheme: selectedAccentTheme,
                    user: user, sessionManager: sessionManager,
                    actions: actions
                )
            }
        }
        .padding(.horizontal, \.sixteen).padding(.top, \.five)
    }

    private var chromeBackground: some View {
        LinearGradient(
            stops: [
                ThemeColorStop(\.black, opacity: \.p0_9),
                ThemeColorStop(\.ink, opacity: \.p0_85),
                ThemeColorStop(\.clear)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }
}
