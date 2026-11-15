import SwiftUI
import DesignTokensKit

struct QuoteCardMetrics {
    let compactStyle: Bool
    let cardHeight: CGFloat?

    var contentSpacing: CGFloat { compactStyle ? SpacingTheme.default.twelve : SpacingTheme.default.eighteen }
    var iconSize: CGFloat { compactStyle ? DesignMetricTheme.default.p21 : DesignMetricTheme.default.p26_5 }
    var quoteFontSize: CGFloat { compactStyle ? DesignMetricTheme.default.p19 : DesignMetricTheme.default.p22_58 }
    var lineSpacing: CGFloat { compactStyle ? SpacingTheme.default.four : SpacingTheme.default.five }
    var authorFontSize: CGFloat { compactStyle ? SpacingTheme.default.twelve : SpacingTheme.default.fourteen }
    var cardPadding: CGFloat { compactStyle ? SpacingTheme.default.eighteen : SpacingTheme.default.twentyFour }
    var cornerRadius: CGFloat {
        compactStyle ? CornerRadiusTheme.default.fourteen : CornerRadiusTheme.default.twenty
    }
    var fixedCardHeight: CGFloat {
        cardHeight ?? (compactStyle ? DesignMetricTheme.default.p248 : DesignMetricTheme.default.p320)
    }
}
