import SwiftUI
import UIKit

#if DEBUG
private extension Notification.Name {
    static let deviceShaken = Notification.Name("MotivationDaily.deviceShaken")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceShaken, object: self)
    }
}

struct DebugSettingsPresenter: UIViewControllerRepresentable {
    var isLaunchSettingsVisible: Bool
    var onApply: () -> Void

    func makeUIViewController(context: Context) -> Presenter { Presenter() }

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
            while let presented = presenter.presentedViewController { presenter = presented }
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
#endif
