import SwiftUI

@main
struct MotivationDailyApp: App {
    private let container = AppContainer.live
    @AppStorage(AccentTheme.storageKey) private var accentThemeRawValue = AccentTheme.default.rawValue

    var body: some Scene {
        WindowGroup {
            HomeView(
                quoteVM: container.makeQuoteViewModel(),
                pageVM: container.makeFeedPageViewModel()
            )
            .tint(AccentTheme.resolve(from: accentThemeRawValue).color)
        }
    }
}
