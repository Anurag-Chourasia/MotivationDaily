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
        case "inspiration": String(\MotivationStrings.categoryInspiration)
        case "wisdom": String(\MotivationStrings.categoryWisdom)
        case "success": String(\MotivationStrings.categorySuccess)
        case "happiness": String(\MotivationStrings.categoryHappiness)
        case "life": String(\MotivationStrings.categoryLife)
        default: displayName
        }
    }
}
