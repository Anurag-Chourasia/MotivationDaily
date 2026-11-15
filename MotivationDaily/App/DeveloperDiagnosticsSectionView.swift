import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

#if DEBUG
struct DeveloperDiagnosticsSectionView: View {
    @Binding var authentication: Bool
    @Binding var logs: Bool
    @Binding var version: String
    @Binding var build: String

    var body: some View {
        Section(header: Text(\.developerFeatureFlags)) {
            Toggle(isOn: $authentication) {
                Text(\.developerAuthentication)
            }
            .accessibilityIdentifier(.developerAuthentication)
            Text(\MotivationStrings.developerAuthNote)
        }
        Section(header: Text(\.developerDebugLogs)) {
            Toggle(isOn: $logs) {
                Text(\.developerHttpLogs)
            }
            Text(\CommonStrings.developerReleaseIgnores)
        }
        Section(header: Text(\.developerVersionSimulation)) {
            LabeledContent(String(\.developerInstalledVersion), value: AppRuntime.actualVersion)
            LabeledContent(String(\.developerInstalledBuild), value: AppRuntime.actualBuild)
            TextField(String(\.developerSimulatedVersion), text: $version)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField(String(\.developerSimulatedBuild), text: $build)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
        }
        Section(header: Text(\.developerPrivacySupport)) {
            let privacyURL = "https://github.com/Anurag-Chourasia/MotivationDaily/blob/main/Docs/PrivacyInventory.md"
            Link(destination: URL(string: privacyURL)!) {
                Label(Text(\.developerPrivacyPolicy), \.handRaised)
            }
            .accessibilityIdentifier(.developerPrivacyPolicy)

            Link(destination: URL(string: "mailto:anuragchourasiaios@gmail.com")!) {
                Label(Text(\.developerSupport), \.envelope)
            }
            .accessibilityIdentifier(.developerSupport)

            Text(\MotivationStrings.developerPrivacy)
                .font(\.caption).foregroundColor(\.secondary)
        }
    }
}
#endif
