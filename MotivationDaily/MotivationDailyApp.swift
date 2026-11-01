import SwiftUI
import AuthKitUI

@main
struct MotivationDailyApp: App {
    private let container = AppContainer.live
    @AppStorage(AccentTheme.storageKey) private var accentThemeRawValue = AccentTheme.default.rawValue

    var body: some Scene {
        WindowGroup {
            appContent
            .tint(AccentTheme.resolve(from: accentThemeRawValue).color)
        }
    }

    @ViewBuilder private var appContent: some View {
        #if DEBUG
        // Existing offline feature journeys use fixture data and never touch Supabase.
        // This branch is absent from Release builds.
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            HomeView(quoteVM: container.makeQuoteViewModel(), pageVM: container.makeFeedPageViewModel())
        } else {
            launchContent
        }
        #else
        launchContent
        #endif
    }

    private var launchContent: some View {
        MotivationLaunchView { authenticationEnabled in
            if authenticationEnabled { authenticatedContent }
            else { HomeView(quoteVM: container.makeQuoteViewModel(), pageVM: container.makeFeedPageViewModel()) }
        }
    }

    private var authenticatedContent: some View {
        AppAuthGate(brand: .motivationDaily) { _, _ in
            HomeView(quoteVM: container.makeQuoteViewModel(), pageVM: container.makeFeedPageViewModel())
        }
    }

}
