import SwiftUI

enum WallpaperAspectRatio: String, CaseIterable, Identifiable {
    case oneToOne = "1:1"
    case sixteenToNine = "16:9"
    case nineToSixteen = "9:16"
    case fullScreen = "Fullscreen"

    var id: String { rawValue }

    var value: CGFloat? {
        switch self {
        case .oneToOne: return 1.0
        case .sixteenToNine: return 16.0 / 9.0
        case .nineToSixteen: return 9.0 / 16.0
        case .fullScreen: return nil
        }
    }

    var components: (width: CGFloat, height: CGFloat)? {
        switch self {
        case .oneToOne: return (1, 1)
        case .sixteenToNine: return (16, 9)
        case .nineToSixteen: return (9, 16)
        case .fullScreen: return nil
        }
    }
}
