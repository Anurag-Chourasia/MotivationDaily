import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "motivationdaily.network.monitor")

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor

        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            isConnected = true
            return
        }

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
