import DesignTokensKit
import LocalizationKit

// Labels are presentation copy; palette values and persisted identifiers stay in their owning types.
extension AccentTheme {
    var localizedDisplayName: String {
        switch self {
        case .default: String(\MotivationStrings.themeDefault)
        case .ocean: String(\MotivationStrings.themeOcean)
        case .mint: String(\MotivationStrings.themeMint)
        case .sunset: String(\MotivationStrings.themeSunset)
        }
    }
}

extension WallpaperAspectRatio {
    var localizedTitle: String {
        self == .fullScreen ? String(\MotivationStrings.ratioFullscreen) : rawValue
    }
}

extension Category {
    var localizedDisplayName: String {
        switch key.rawValue {
        case "focus": String(\MotivationStrings.categoryFocus)
        case "growth": String(\MotivationStrings.categoryGrowth)
        case "inspiration": String(\MotivationStrings.categoryInspiration)
        case "wisdom": String(\MotivationStrings.categoryWisdom)
        case "success": String(\MotivationStrings.categorySuccess)
        case "happiness": String(\MotivationStrings.categoryHappiness)
        case "life": String(\MotivationStrings.categoryLife)
        default: displayName
        }
    }
}

extension AppError {
    func localizedMessage(
        in context: LocalizedContext<MotivationDomain> = .shared,
        fallbackKeyPath: KeyPath<MotivationStrings, String>? = \.errorRefresh
    ) -> String {
        switch semanticCode {
        case .invalidURL:
            return context[\.errorInvalidUrl]
        case .blocked:
            return context[\.errorBlocked]
        case .notFound:
            return context[\.errorNotFound]
        case .timeout:
            return context[\.errorTimeout]
        case .rateLimited:
            return context[\.errorRateLimited]
        case .serverUnavailable:
            return context[\.errorServerUnavailable]
        case .networkStatus(let status):
            return context.string("motivation.error.network_status", arguments: [status])
        case .invalidResponse:
            return context[\.errorInvalidResponse]
        case .imageLoadFailed:
            return context[\.errorImageLoadFailed]
        case .decoding:
            return context[\.errorDecoding]
        case .storage:
            return context[\.errorStorage]
        case .imageNotReady:
            return context[\.errorImageNotReady]
        case .emptyResponse:
            return context[\.errorEmptyResponse]
        case .untrustedNetworkMessage, .unknown:
            if let fallbackKeyPath {
                return context[fallbackKeyPath]
            }
            return context[\CommonStrings.errorGeneric]
        }
    }

    func localizedRecoverySuggestion(
        in context: LocalizedContext<MotivationDomain> = .shared
    ) -> String? {
        guard let semanticRecovery else { return nil }
        switch semanticRecovery {
        case .rateLimited:
            return context[\.recoveryRateLimited]
        case .serverUnavailable:
            return context[\.recoveryServerUnavailable]
        case .network:
            return context[\.recoveryNetwork]
        case .refresh:
            return context[\.recoveryRefresh]
        case .storage:
            return context[\.recoveryStorage]
        }
    }
}
