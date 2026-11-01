import SwiftUI
import DesignTokensKit

struct MotivationLaunchView<Content: View>: View {
    let content: (Bool) -> Content
    @State private var authenticationEnabled = AppRuntime.authenticationEnabled

    init(@ViewBuilder content: @escaping (Bool) -> Content) { self.content = content }

    #if DEBUG
    @State private var showingLaunchSettings = true
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
                content(authenticationEnabled).id(configurationID)
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
    @AppStorage("developer.authentication") private var authentication = false
    @AppStorage("developer.httpLogs") private var logs = false
    @AppStorage("developer.version") private var version = ""
    @AppStorage("developer.build") private var build = ""

    var body: some View {
        Form {
            Section {
                Text("Configure Motivation Daily, then continue. Shake the device from any screen to return to these settings.")
                Button(buttonTitle, action: onContinue)
                    .accessibilityIdentifier("developer-open-app")
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
            Section {
                Button("Reset developer settings", role: .destructive) {
                    authentication = false; logs = false; version = ""; build = ""
                }
            }
        }
        .navigationTitle("Developer settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
