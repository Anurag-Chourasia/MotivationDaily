import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

#if DEBUG
struct DeveloperSettingsView: View {
    var buttonTitle = String(\MotivationStrings.applyAndClose)
    var cacheStatsProvider: () -> (count: Int, formattedSize: String) = {
        (QuoteDiskCache.shared.entryCount, QuoteDiskCache.shared.formattedFileSize)
    }
    var onClearCache: () -> Void = { QuoteDiskCache.shared.clear() }
    var onContinue: () -> Void
    @AppStorage("developer.source") private var source = "live"
    @AppStorage("developer.scenario") private var scenario = "success"
    @AppStorage("developer.authentication") private var authentication = false
    @AppStorage("developer.httpLogs") private var logs = false
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""
    @State private var cacheSummary = ""

    var body: some View {
        Form {
            Section {
                Text(\.developerSettingsSubtitleMotivation)
                Button(buttonTitle, action: onContinue).accessibilityIdentifier(.developerOpenApp)
            }
            DeveloperPresetsSectionView(source: $source, scenario: $scenario, onContinue: onContinue)
            Section(header: Text(\.developerCacheAndOffline)) {
                let cacheValue = cacheSummary.isEmpty ? String(\.developerChecking) : cacheSummary
                LabeledContent(String(\.developerDiskCache), value: cacheValue)
                Button(role: .destructive) {
                    onClearCache(); refreshCacheSummary()
                } label: {
                    Text(\.developerPurgeQuoteCache)
                }
                .accessibilityIdentifier(.developerPurgeCache)
            }
            Section(header: Text(\.developerEnvironment)) {
                Picker(String(\.developerDataSource), selection: $source) {
                    Text(\MotivationStrings.developerLive).tag("live")
                    Text(\CommonStrings.developerSourceStub).tag("stub")
                }
                if source == "stub" {
                    Picker(String(\.developerScenario), selection: $scenario) {
                        Text(\.developerPresetShowcase).tag("showcase")
                        Text(\.developerScenarioSuccess).tag("success")
                        Text(\.developerScenarioEmpty).tag("empty")
                        Text(\.developerScenarioOffline).tag("offline")
                    }
                }
                Text(\MotivationStrings.developerStubNote)
            }
            DeveloperDiagnosticsSectionView(
                authentication: $authentication, logs: $logs, version: $version, build: $build
            )
            Section {
                Button(role: .destructive) {
                    source = "live"; scenario = "success"
                    authentication = false; logs = false; version = ""; build = ""
                } label: {
                    Text(\.developerResetSettings)
                }
            }
        }
        .navigationTitle(Text(\.developerSettingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshCacheSummary() }
    }

    private func refreshCacheSummary() {
        let stats = cacheStatsProvider()
        let count = stats.count
        if count == 0 {
            cacheSummary = String(\MotivationStrings.developerCacheEmpty)
        } else {
            cacheSummary = String(
                format: String(\MotivationStrings.developerCacheSummary),
                locale: LocalizationController.shared.locale,
                count, stats.formattedSize
            )
        }
    }
}
#endif
