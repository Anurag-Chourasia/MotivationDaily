import SwiftUI
import DeveloperProfileKit
import DesignTokensKit
import UIComponentsKit

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
            .background(DesignColor.grouped)
            .tint(DesignColor.primary)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    AboutView()
}
