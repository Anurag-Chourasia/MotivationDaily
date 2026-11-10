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
                    DeveloperSettingsView(buttonTitle: String(\CommonStrings.developerOpenApp)) {
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
                            DeveloperSettingsView(buttonTitle: String(\CommonStrings.close)) {
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
                Text(\.showcaseDemoTitle)
                    .font(\.caption)
                    .fontWeight(.bold)
                Text(\.showcaseDemoTapForControls)
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
        .padding(.horizontal, \.sixteen)
        .accessibilityIdentifier(.showcaseDemoIndicator)
        .accessibilityLabel(\.showcaseDemoA11y)
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
                Text(\.developerSettingsSubtitleMotivation)
                Button(buttonTitle, action: onContinue)
                    .accessibilityIdentifier(.developerOpenApp)
            }
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
            Section(header: Text(\.developerCacheAndOffline)) {
                LabeledContent(String(\.developerDiskCache), value: cacheSummary.isEmpty ? String(\.developerChecking) : cacheSummary)
                Button(role: .destructive) {
                    diskCache.clear()
                    refreshCacheSummary()
                } label: {
                    Text(\.developerPurgeQuoteCache)
                }
                .accessibilityIdentifier(.developerPurgeCache)
            }
            Section(header: Text(\.developerEnvironment)) {
                Picker(String(\.developerDataSource), selection: $source) {
                    Text(String(\MotivationStrings.developerLive)).tag("live")
                    Text(String(\CommonStrings.developerSourceStub)).tag("stub")
                }
                if source == "stub" {
                    Picker(String(\.developerScenario), selection: $scenario) {
                        Text(\.developerPresetShowcase).tag("showcase")
                        Text(\.developerScenarioSuccess).tag("success")
                        Text(\.developerScenarioEmpty).tag("empty")
                        Text(\.developerScenarioOffline).tag("offline")
                    }
                }
                Text(String(\MotivationStrings.developerStubNote))
            }
            Section(header: Text(\.developerFeatureFlags)) {
                Toggle(isOn: $authentication) {
                    Text(\.developerAuthentication)
                }
                .accessibilityIdentifier(.developerAuthentication)
                Text(String(\MotivationStrings.developerAuthNote))
            }
            Section(header: Text(\.developerDebugLogs)) {
                Toggle(isOn: $logs) {
                    Text(\.developerHttpLogs)
                }
                Text(String(\CommonStrings.developerReleaseIgnores))
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
                Link(destination: URL(string: "https://github.com/Anurag-Chourasia/Motivation-Daily/blob/main/Docs/PrivacyInventory.md")!) {
                    Label(Text(\.developerPrivacyPolicy), \.handRaised)
                }
                .accessibilityIdentifier(.developerPrivacyPolicy)

                Link(destination: URL(string: "mailto:anuragchourasiaios@gmail.com")!) {
                    Label(Text(\.developerSupport), \.envelope)
                }
                .accessibilityIdentifier(.developerSupport)

                Text(String(\MotivationStrings.developerPrivacy))
                    .font(\.caption)
                    .foregroundColor(\.secondary)
            }
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
