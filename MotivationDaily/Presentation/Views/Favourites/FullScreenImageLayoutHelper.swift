import SwiftUI
import UIKit
import DesignTokensKit

enum FullScreenImageLayoutHelper {
    static func imageRect(for image: UIImage, in containerSize: CGSize, ratio: WallpaperAspectRatio) -> CGRect {
        guard containerSize.width > 0, containerSize.height > 0 else { return .zero }
        if ratio == .fullScreen { return CGRect(origin: .zero, size: containerSize) }
        if let explicitRatio = ratio.value {
            let width = containerSize.width
            let height = width / max(explicitRatio, 0.01)
            let y = (containerSize.height - height) / 2.0
            return CGRect(x: 0, y: y, width: width, height: height)
        }
        let imageWidth = max(image.size.width, 1)
        let imageHeight = max(image.size.height, 1)
        let ratio = imageWidth / imageHeight
        let width = containerSize.width
        let height = width / ratio
        let y = (containerSize.height - height) / 2.0
        return CGRect(x: 0, y: y, width: width, height: height)
    }

    static func resolvedQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let style = QuoteCardLayout.style(for: imageRect)
        let minH = style.isCompact ? DesignMetric.p160 : DesignMetric.p210
        let prefH = style.isCompact ? DesignMetric.p248 : DesignMetric.p320
        let availableH = max(imageRect.height - Spacing.twelve, 1)
        return min(prefH, max(availableH, minH))
    }

    static func fullScreenCanvasSize(for proxy: GeometryProxy) -> CGSize {
        let width = max(proxy.size.width, UIScreen.main.bounds.width)
        let height = max(
            proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
            UIScreen.main.bounds.height
        )
        return CGSize(width: width, height: height)
    }

    static func shareLayoutSize(
        for favorite: FavoriteQuote?,
        displayedImage: UIImage?,
        selectedRatio: WallpaperAspectRatio
    ) -> CGSize? {
        let scale = max(UIScreen.main.scale, 1)
        if selectedRatio == .fullScreen { return UIScreen.main.bounds.size }
        if let favorite, let width = favorite.imageWidth, width > 0 {
            let widthPoints = CGFloat(width) / scale
            if let ratio = selectedRatio.value {
                return CGSize(width: widthPoints, height: widthPoints / max(ratio, 0.01))
            }
            if let height = favorite.imageHeight, height > 0 {
                return CGSize(width: widthPoints, height: CGFloat(height) / scale)
            }
        }
        if let displayedImage {
            let maxDimension = CGFloat(1920)
            if let ratio = selectedRatio.value {
                let rawWidth = min(max(displayedImage.size.width, UIScreen.main.bounds.width), maxDimension)
                let calculatedHeight = rawWidth / max(ratio, 0.01)
                if calculatedHeight > maxDimension {
                    let scaledWidth = maxDimension * ratio
                    return CGSize(width: max(round(scaledWidth), 1), height: maxDimension)
                }
                return CGSize(width: max(round(rawWidth), 1), height: max(round(calculatedHeight), 1))
            }
            let largest = max(displayedImage.size.width, displayedImage.size.height)
            if largest > maxDimension {
                let scale = maxDimension / largest
                return CGSize(
                    width: max(round(displayedImage.size.width * scale), 1),
                    height: max(round(displayedImage.size.height * scale), 1)
                )
            }
            return displayedImage.size
        }
        return nil
    }
}
