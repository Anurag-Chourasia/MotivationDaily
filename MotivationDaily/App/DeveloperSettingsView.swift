import SwiftUI
import DesignTokensKit

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
                    DeveloperSettingsView(buttonTitle: "Open Motivation Daily") {
                        authenticationEnabled = AppRuntime.authenticationEnabled
                        showingLaunchSettings = false
                    }
                }
            } else {
                content(authenticationEnabled)
                    .id(configurationID)
                    .safeAreaInset(edge: .top) {
                        if AppRuntime.isShowcaseMode {
                            ShowcaseBadgeView {
                                showingSettingsSheet = true
                            }
                        }
                    }
                    .sheet(isPresented: $showingSettingsSheet) {
                        NavigationStack {
                            DeveloperSettingsView(buttonTitle: "Close") {
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

#if DEBUG
struct ShowcaseBadgeView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: \.four) {
                Image(\.sparkles)
                    .font(\.caption2)
                Text("SHOWCASE DEMO")
                    .font(\.caption)
                    .fontWeight(.bold)
                Text("• Tap for Controls")
                    .font(\.caption2)
                    .opacity(\.p0_5)
            }
            .padding(.horizontal, \.ten)
            .padding(.vertical, \.four)
            .background(.ultraThinMaterial)
            .foregroundColor(\.primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(\.primary, opacity: \.p0_35, lineWidth: \.one)
            )
        }
        .padding(.top, \.four)
        .accessibilityIdentifier("showcase-demo-indicator")
        .accessibilityLabel("Showcase demo mode. Tap to open developer settings.")
    }
}
#endif

#if DEBUG
private extension Notification.Name {
    static let deviceShaken = Notification.Name("MotivationDaily.deviceShaken")
}

// The window remains in the responder chain across navigation, keyboards,
// and presented sheets. Do not take first responder away from text fields.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceShaken, object: self)
    }
}

private struct DebugSettingsPresenter: UIViewControllerRepresentable {
    var isLaunchSettingsVisible: Bool
    var onApply: () -> Void

    func makeUIViewController(context: Context) -> Presenter {
        Presenter()
    }

    func updateUIViewController(_ controller: Presenter, context: Context) {
        controller.isLaunchSettingsVisible = isLaunchSettingsVisible
        controller.onApply = onApply
    }

    final class Presenter: UIViewController, UIAdaptivePresentationControllerDelegate {
        var isLaunchSettingsVisible = false
        var onApply: () -> Void = {}
        private weak var settingsController: UIViewController?

        override func viewDidLoad() {
            super.viewDidLoad()
            NotificationCenter.default.addObserver(self, selector: #selector(showSettings(_:)),
                                                   name: .deviceShaken, object: nil)
        }

        deinit { NotificationCenter.default.removeObserver(self) }

        @objc private func showSettings(_ notification: Notification) {
            guard let window = notification.object as? UIWindow,
                  window === view.window,
                  !isLaunchSettingsVisible, settingsController == nil,
                  var presenter = window.rootViewController else { return }
            // Present above the currently open sheet, preserving its navigation state.
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            guard !presenter.isBeingDismissed, !presenter.isBeingPresented else { return }
            let settings = UIHostingController(rootView: NavigationStack {
                DeveloperSettingsView { [weak self] in
                    self?.settingsController?.dismiss(animated: true) {
                        self?.settingsController = nil
                        self?.onApply()
                    }
                }
            })
            settingsController = settings
            presenter.present(settings, animated: true)
            settings.presentationController?.delegate = self
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            settingsController = nil
            onApply()
        }
    }
}

struct DeveloperSettingsView: View {
    var buttonTitle = "Apply and close"
    var onContinue: () -> Void
    @AppStorage("developer.source") private var source = "live"
    @AppStorage("developer.scenario") private var scenario = "success"
    @AppStorage("developer.authentication") private var authentication = false
    @AppStorage("developer.httpLogs") private var logs = false
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""
    @State private var cacheSummary = ""

    private let diskCache = QuoteDiskCache.shared

    var body: some View {
        Form {
            Section {
                Text("Configure Motivation Daily runtime, cache, and feature flags. Shake device from any screen to reopen.")
                Button(buttonTitle, action: onContinue)
                    .accessibilityIdentifier("developer-open-app")
            }
            Section("Quick presets") {
                Button {
                    source = "stub"
                    scenario = "showcase"
                    onContinue()
                } label: {
                    Label("Showcase (Populated)", systemImage: "sparkles")
                }
                .accessibilityIdentifier("developer-preset-showcase")

                Button {
                    source = "stub"
                    scenario = "empty"
                    onContinue()
                } label: {
                    Label("Empty State (Zero Results)", systemImage: "tray")
                }
                .accessibilityIdentifier("developer-preset-empty")

                Button {
                    source = "stub"
                    scenario = "offline"
                    onContinue()
                } label: {
                    Label("Offline Resilience", systemImage: "wifi.slash")
                }
                .accessibilityIdentifier("developer-preset-offline")

                Button {
                    source = "live"
                    onContinue()
                } label: {
                    Label("Live Feed", systemImage: "globe")
                }
                .accessibilityIdentifier("developer-preset-live")
            }
            Section("Cache & offline storage") {
                LabeledContent("Disk cache", value: cacheSummary.isEmpty ? "Checking..." : cacheSummary)
                Button("Purge quote cache", role: .destructive) {
                    diskCache.clear()
                    refreshCacheSummary()
                }
                .accessibilityIdentifier("developer-purge-cache")
            }
            Section("Environment") {
                Picker("Data source", selection: $source) {
                    Text("Live · Quotable & ZenQuotes").tag("live")
                    Text("Stub · local fixtures").tag("stub")
                }
                if source == "stub" {
                    Picker("Scenario", selection: $scenario) {
                        Text("Success").tag("success")
                        Text("Empty results").tag("empty")
                        Text("Offline error").tag("offline")
                    }
                }
                Text("Stub mode uses local quotes and wallpapers without making remote network requests.")
            }
            Section("Feature flags") {
                Toggle("Authentication · AuthKit", isOn: $authentication)
                    .accessibilityIdentifier("developer-authentication")
                Text("New feature, off by default. Enable to require sign-in before the feed. Apply settings to activate changes; disabling it preserves the saved session.")
            }
            Section("Debug logs") {
                Toggle("HTTP logs in Xcode console", isOn: $logs)
                Text("Release builds ignore this setting.")
            }
            Section("Version simulation") {
                LabeledContent("Installed version", value: AppRuntime.actualVersion)
                LabeledContent("Installed build", value: AppRuntime.actualBuild)
                TextField("Simulated version", text: $version)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("Simulated build", text: $build)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            Section("Privacy & Support") {
                Link(destination: URL(string: "https://github.com/Anurag-Chourasia/Motivation-Daily/blob/main/Docs/PrivacyInventory.md")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                .accessibilityIdentifier("developer-privacy-policy")

                Link(destination: URL(string: "mailto:anuragchourasiaios@gmail.com")!) {
                    Label("Developer Support", systemImage: "envelope")
                }
                .accessibilityIdentifier("developer-support")

                Text("Motivation Daily stores favorited quotes and lightweight settings locally on your device. Quote and wallpaper fetching is unauthenticated. No personal data is tracked or sold to third parties.")
                    .font(\.caption)
                    .foregroundColor(\.secondary)
            }
            Section {
                Button("Reset developer settings", role: .destructive) {
                    source = "live"; scenario = "success"
                    authentication = false; logs = false; version = ""; build = ""
                }
            }
        }
        .navigationTitle("Developer settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshCacheSummary()
        }
    }

    private func refreshCacheSummary() {
        let count = diskCache.entryCount
        if count == 0 {
            cacheSummary = "0 quotes (0 KB)"
        } else {
            cacheSummary = "\(count) quotes (\(diskCache.formattedFileSize))"
        }
    }
}
#endif
