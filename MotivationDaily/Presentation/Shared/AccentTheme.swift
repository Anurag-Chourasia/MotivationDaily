import SwiftUI

enum AccentTheme: String, CaseIterable, Identifiable {
    case `default`
    case ocean
    case mint
    case sunset

    static let storageKey = "accent_theme_selection"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .ocean:
            return "Ocean"
        case .mint:
            return "Mint"
        case .sunset:
            return "Sunset"
        }
    }

    var assetName: String {
        switch self {
        case .default:
            return "AccentColor"
        case .ocean:
            return "AccentOcean"
        case .mint:
            return "AccentMint"
        case .sunset:
            return "AccentSunset"
        }
    }

    var color: Color {
        Color(assetName)
    }

    static func resolve(from rawValue: String) -> AccentTheme {
        AccentTheme(rawValue: rawValue) ?? .default
    }
}
