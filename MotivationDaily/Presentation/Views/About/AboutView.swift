import SwiftUI
import DeveloperProfileKit
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

@MainActor
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AboutViewModel

    init(viewModel: AboutViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init() {
        _viewModel = StateObject(wrappedValue: AboutViewModel())
    }

    var body: some View {
        NavigationStack {
            DeveloperProfileView(
                app: DeveloperAppInfo(
                    name: viewModel.appName,
                    version: viewModel.version,
                    build: viewModel.build,
                    disclaimer: viewModel.disclaimer
                ),
                layout: .list,
                labels: viewModel.profileLabels
            )
            .background(\.grouped)
            .tint(\.primary)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(\.close)
                    }
                    .accessibilityLabel(\.close)
                    .accessibilityIdentifier(.aboutBackButton)
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
