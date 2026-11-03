import SwiftUI
import DeveloperProfileKit
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AboutViewModel

    init(viewModel: AboutViewModel = AboutViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Label(\.back, \.chevronLeft)
                    }
                    .accessibilityIdentifier("about.backButton")
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    AboutView()
}
