import DesignTokensKit
import SwiftUI
import AuthKitUI
import AuthKit
import LocalizationKit

extension LocalizationController: @retroactive AuthLocalizing {}

@main
struct MotivationDailyApp: App {
    private var container: AppContainer {
        AppContainer.makeCurrent()
    }
    @AppStorage(AccentTheme.storageKey) private var accentThemeRawValue = AccentTheme.default.rawValue

    var body: some Scene {
        WindowGroup {
            appContent
            .tint(AccentTheme.resolve(from: accentThemeRawValue).color)
            .environment(\.layoutDirection, container.localization.isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }

    @ViewBuilder private var appContent: some View {
        #if DEBUG
        // Existing offline feature journeys use fixture data and never touch Supabase.
        // This branch is absent from Release builds.
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            let active = container
            HomeView(quoteVM: active.makeQuoteViewModel(), pageVM: active.makeFeedPageViewModel())
        } else {
            launchContent
        }
        #else
        launchContent
        #endif
    }

    private var launchContent: some View {
        MotivationLaunchView { authenticationEnabled in
            let active = container
            if authenticationEnabled {
                authenticatedContent(container: active)
            } else {
                HomeView(quoteVM: active.makeQuoteViewModel(), pageVM: active.makeFeedPageViewModel())
            }
        }
    }

    private func authenticatedContent(container: AppContainer) -> some View {
        AppAuthGate(
            brand: .motivationDaily,
            backendFactory: container.authBackendFactory,
            localizer: container.localization
        ) { user, sessionManager in
            let accountContainer = AppContainer.makeCurrent(favoritesOwnerID: user.id)
            HomeView(
                quoteVM: accountContainer.makeQuoteViewModel(),
                pageVM: accountContainer.makeFeedPageViewModel(),
                user: user,
                sessionManager: sessionManager
            )
            .id(user.id)
        }
    }
}
