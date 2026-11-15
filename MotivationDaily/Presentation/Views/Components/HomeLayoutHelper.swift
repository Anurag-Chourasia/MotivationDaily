import SwiftUI
import DesignTokensKit

enum HomeLayoutHelper {
    static func wallpaperRect(in container: CGSize, ratio: WallpaperAspectRatio) -> CGRect {
        guard container.width > 0, container.height > 0 else { return .zero }
        guard let ratioValue = ratio.value else {
            return CGRect(origin: .zero, size: container)
        }
        let width = container.width
        let height = width / max(ratioValue, 0.01)
        return CGRect(
            x: 0,
            y: (container.height - height) / 2.0,
            width: width,
            height: height
        )
    }

    static func resolvedQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let layout = QuoteCardLayout.style(for: imageRect)
        let minH = layout.isCompact ? DesignMetric.p160 : DesignMetric.p210
        let prefH = layout.isCompact ? DesignMetric.p248 : DesignMetric.p320
        let availableH = max(imageRect.height - Spacing.twelve, 1)
        return min(prefH, max(availableH, minH))
    }
}

struct HomeTopChromeActions {
    let onSelectTheme: (AccentTheme) -> Void
    let onSelectCategory: (CategoryKey?) -> Void
    let onShowFavorites: () -> Void
    let onShowAbout: () -> Void
    let onRequestDeleteAccount: () -> Void
}

struct FeedAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum FeedBootPhase {
    case cold
    case preparing
    case ready
}
