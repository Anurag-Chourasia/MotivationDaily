import CoreGraphics

struct QuoteCardLayout {
    let width: CGFloat
    let isCompact: Bool

    static func style(for imageRect: CGRect) -> QuoteCardLayout {
        let isCompact = imageRect.height <= 420
        let widthRatio: CGFloat = isCompact ? 0.80 : 0.86
        let minWidth: CGFloat = isCompact ? 180 : 220
        let maxWidth: CGFloat = isCompact ? 360 : 460
        let width = max(min(imageRect.width * widthRatio, maxWidth), minWidth)
        return QuoteCardLayout(width: width, isCompact: isCompact)
    }

    static func style(for size: CGSize) -> QuoteCardLayout {
        style(for: CGRect(origin: .zero, size: size))
    }
}
