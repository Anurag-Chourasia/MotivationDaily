import Foundation
import FoundationKit

/// Application runtime environment, version info, and configuration powered by FoundationKit.
enum AppRuntime {
    static let actualVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let actualBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    static var environment: BuildEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }

    static var version: String {
        #if DEBUG
        let value = UserDefaults.standard.string(forKey: "developer.version")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? actualVersion : value
        #else
        return actualVersion
        #endif
    }

    static var build: String {
        #if DEBUG
        let value = UserDefaults.standard.string(forKey: "developer.build")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? actualBuild : value
        #else
        return actualBuild
        #endif
    }

    static let configuration = AppConfiguration(
        environment: environment,
        apiBaseURL: URL(string: "https://api.quotable.io"),
        featureFlags: FeatureFlags(values: [
            "quotes.randomize": true,
            "wallpapers.cache": true,
            "offline.stubs": true
        ])
    )

    static let logger: AppLogger = ConsoleLogger(
        subsystem: "com.anurag.MotivationDaily",
        category: "App"
    )

    static let clock: AppClock = SystemClock()
}
