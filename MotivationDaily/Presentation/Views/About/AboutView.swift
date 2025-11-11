import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: AboutViewModel

    init(viewModel: AboutViewModel = AboutViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    developerSection
                    appSection
                    socialSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Unable to Open Link", isPresented: $viewModel.showInvalidLinkAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again later.")
        }
    }

    private var developerSection: some View {
        VStack(spacing: 10) {
            Image("Anurag")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .foregroundColor(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            Text(viewModel.developerName)
                .font(.title3.weight(.semibold))

            Text(viewModel.developerRole)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.appName)
                .font(.headline)
            Text(viewModel.appDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(viewModel.versionText)
                .font(.footnote)
                .foregroundColor(.secondary)
            Text(viewModel.disclaimer)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connect")
                .font(.headline)

            ForEach(viewModel.socialLinks) { link in
                Button {
                    openURL(link.url) { accepted in
                        if !accepted {
                            viewModel.showInvalidLinkAlert = true
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(link.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .accessibilityHidden(true)

                        Text(link.title)
                            .font(.body.weight(.medium))
                            .foregroundColor(.primary)

                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    AboutView()
}
