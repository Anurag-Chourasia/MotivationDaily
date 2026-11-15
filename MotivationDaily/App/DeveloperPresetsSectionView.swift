import SwiftUI
import LocalizationKit
import DesignTokensKit
import UIComponentsKit

#if DEBUG
struct DeveloperPresetsSectionView: View {
    @Binding var source: String
    @Binding var scenario: String
    let onContinue: () -> Void

    var body: some View {
        Section(header: Text(\.developerQuickPresets)) {
            Button {
                source = "stub"
                scenario = "showcase"
                onContinue()
            } label: {
                Label(Text(\.developerPresetShowcase), \.sparkles)
            }
            .accessibilityIdentifier(.developerPresetShowcase)

            Button {
                source = "stub"
                scenario = "empty"
                onContinue()
            } label: {
                Label(Text(\.developerPresetEmpty), \.tray)
            }
            .accessibilityIdentifier(.developerPresetEmpty)

            Button {
                source = "stub"
                scenario = "offline"
                onContinue()
            } label: {
                Label(Text(\.developerPresetOffline), \.wifiSlash)
            }
            .accessibilityIdentifier(.developerPresetOffline)

            Button {
                source = "live"
                onContinue()
            } label: {
                Label(Text(\.developerPresetLiveFeed), \.globe)
            }
            .accessibilityIdentifier(.developerPresetLive)
        }
    }
}
#endif
