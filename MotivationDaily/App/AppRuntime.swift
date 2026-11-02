import Foundation
import FoundationKit

/// Application runtime environment, version info, and configuration powered by FoundationKit.
enum AppRuntime {
    /// Debug opt-in; production rollout never reads developer preferences.
    static var authenticationEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "developer.authentication")
        #else
        return Bundle.main.object(forInfoDictionaryKey: "AUTHKIT_ENABLED") as? Bool ?? false
        #endif
    }

    static let actualVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let actualBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    static var environment: BuildEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }

    static var dataSource: String {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "developer.source") ?? "live"
        #else
        return "live"
        #endif
    }

    #if DEBUG
    /// Indicates whether the app was launched with the Showcase CLI argument or environment.
    static var isShowcaseLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("-Showcase") ||
        ProcessInfo.processInfo.arguments.contains("-ShowcaseMode") ||
        ProcessInfo.processInfo.environment["SHOWCASE_MODE"] == "1"
    }

    /// True when running in the curated credential-free Showcase experience.
    static var isShowcaseMode: Bool {
        if let scenario = stubScenario {
            return scenario == "showcase" || isShowcaseLaunch
        }
        return isShowcaseLaunch
    }
    #else
    static var isShowcaseLaunch: Bool { false }
    static var isShowcaseMode: Bool { false }
    #endif

    static var stubScenario: String? {
        #if DEBUG
        let source = UserDefaults.standard.string(forKey: "developer.source")
        if source == "live" { return nil }
        if source == "stub" {
            let scenario = UserDefaults.standard.string(forKey: "developer.scenario") ?? "success"
            return ["success", "showcase", "empty", "offline"].contains(scenario) ? scenario : "success"
        }
        if isShowcaseLaunch { return "showcase" }
        return nil
        #else
        return nil
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
