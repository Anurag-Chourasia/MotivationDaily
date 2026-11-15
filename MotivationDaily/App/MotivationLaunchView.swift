import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct MotivationLaunchView<Content: View>: View {
    let content: (Bool) -> Content
    @State private var authenticationEnabled = AppRuntime.authenticationEnabled

    init(@ViewBuilder content: @escaping (Bool) -> Content) { self.content = content }

    #if DEBUG
    @State private var showingLaunchSettings = !AppRuntime.isShowcaseLaunch
    @State private var showingSettingsSheet = false
    @State private var configurationID = UUID()
    #endif

    var body: some View {
        #if DEBUG
        Group {
            if showingLaunchSettings {
                NavigationStack {
                    DeveloperSettingsView(
                        buttonTitle: String(\CommonStrings.developerOpenApp),
                        cacheStatsProvider: { (QuoteDiskCache.shared.entryCount, QuoteDiskCache.shared.formattedFileSize) },
                        onClearCache: { QuoteDiskCache.shared.clear() }
                    ) {
                        authenticationEnabled = AppRuntime.authenticationEnabled
                        showingLaunchSettings = false
                    }
                }
            } else {
                VStack(spacing: \.zero) {
                    if AppRuntime.isShowcaseMode {
                        ShowcaseBadgeView { showingSettingsSheet = true }
                    }
                    content(authenticationEnabled).id(configurationID)
                }
                .sheet(isPresented: $showingSettingsSheet) {
                    NavigationStack {
                        DeveloperSettingsView(
                            buttonTitle: String(\CommonStrings.close),
                            cacheStatsProvider: { (QuoteDiskCache.shared.entryCount, QuoteDiskCache.shared.formattedFileSize) },
                            onClearCache: { QuoteDiskCache.shared.clear() }
                        ) {
                            showingSettingsSheet = false
                            authenticationEnabled = AppRuntime.authenticationEnabled
                            configurationID = UUID()
                        }
                    }
                }
            }
        }
        .background(DebugSettingsPresenter(isLaunchSettingsVisible: showingLaunchSettings) {
            authenticationEnabled = AppRuntime.authenticationEnabled
            configurationID = UUID()
        })
        #else
        content(authenticationEnabled)
        #endif
    }
}
